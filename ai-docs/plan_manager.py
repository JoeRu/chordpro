#!/usr/bin/env python3
"""Central management CLI for ai-docs XML lifecycle updates.

This tool centralizes write operations for:
- ai-docs/overview-features-bugs.xml
- ai-docs/overview-features-bugs-archive.xml
- ai-docs/overview.xml

It keeps the existing inline XML model and focuses on deterministic, schema-safe edits.
"""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
import xml.etree.ElementTree as ET


DATE_FMT = "%Y-%m-%d"
STATUS_VALUES = {
    "PENDING",
    "APPROVED",
    "PLANNED",
    "IN_PROGRESS",
    "REVIEW",
    "DONE",
    "FAILED",
    "DENIED",
}


@dataclass
class Paths:
    plan: Path
    archive: Path
    overview: Path
    lessons: Path


class PlanManagerError(Exception):
    pass


def today_str() -> str:
    return dt.date.today().strftime(DATE_FMT)


def parse_xml(path: Path) -> ET.ElementTree:
    try:
        return ET.parse(path)
    except FileNotFoundError as exc:
        raise PlanManagerError(f"Missing XML file: {path}") from exc
    except ET.ParseError as exc:
        raise PlanManagerError(f"Invalid XML in {path}: {exc}") from exc


def ensure_child(parent: ET.Element, name: str) -> ET.Element:
    node = parent.find(name)
    if node is None:
        node = ET.SubElement(parent, name)
    return node


def set_or_create_text(parent: ET.Element, name: str, text: str) -> ET.Element:
    node = ensure_child(parent, name)
    node.text = text
    return node


def indent_tree(root: ET.Element) -> None:
    ET.indent(root, space="  ")


def write_xml(tree: ET.ElementTree, path: Path) -> None:
    root = tree.getroot()
    indent_tree(root)
    tree.write(path, encoding="UTF-8", xml_declaration=True, short_empty_elements=False)


def csv_to_ids(raw: str | None) -> list[str]:
    if not raw:
        return []
    out: list[str] = []
    for part in raw.split(","):
        p = part.strip()
        if p:
            out.append(p)
    return out


def next_numeric_item_id(items_node: ET.Element, archive_node: ET.Element | None = None) -> int:
    ids: list[int] = []
    for node in items_node.findall("item"):
        raw = node.get("id", "")
        if raw.isdigit():
            ids.append(int(raw))
    if archive_node is not None:
        for node in archive_node.findall("item"):
            raw = node.get("id", "")
            if raw.isdigit():
                ids.append(int(raw))
    return (max(ids) + 1) if ids else 1


def next_prefixed_id(root: ET.Element, section: str, prefix: str) -> str:
    container = root.find(section)
    if container is None:
        return f"{prefix}-1"
    max_no = 0
    for node in container.findall(section[:-1]):
        raw = node.get("id", "")
        m = re.match(rf"^{re.escape(prefix)}-(\d+)$", raw)
        if m:
            max_no = max(max_no, int(m.group(1)))
    return f"{prefix}-{max_no + 1}"


def append_changelog_entry(plan_root: ET.Element, date_text: str, text: str) -> None:
    changelog = ensure_child(plan_root, "changelog")
    entry = ET.Element("entry", {"date": date_text})
    entry.text = text
    # Keep most recent entries first.
    changelog.insert(0, entry)


def rotate_changelog(plan_root: ET.Element, archive_root: ET.Element, keep: int = 30) -> int:
    changelog = ensure_child(plan_root, "changelog")
    entries = list(changelog.findall("entry"))
    if len(entries) <= keep:
        return 0
    overflow = entries[keep:]
    for node in overflow:
        changelog.remove(node)

    hist = ensure_child(archive_root, "changelog-history")
    # Insert oldest first at top of history for readability.
    for node in reversed(overflow):
        hist.insert(0, copy.deepcopy(node))

    return len(overflow)


def update_metadata_updated(root: ET.Element, date_text: str) -> None:
    metadata = ensure_child(root, "metadata")
    set_or_create_text(metadata, "updated", date_text)


def branch_slug(item_type: str, item_id: str, title: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    slug = "-".join([part for part in slug.split("-") if part][:6]) or "item"
    return f"{item_type}/item-{item_id}-{slug}"


def add_workflow_log(item_node: ET.Element, date_text: str, role: str, action: str, from_status: str, to_status: str) -> None:
    log = ensure_child(item_node, "workflow-log")
    ET.SubElement(
        log,
        "entry",
        {
            "timestamp": date_text,
            "role": role,
            "action": action,
            "from-status": from_status,
            "to-status": to_status,
        },
    )


def find_item(items_node: ET.Element, item_id: str) -> ET.Element:
    node = items_node.find(f"item[@id='{item_id}']")
    if node is None:
        raise PlanManagerError(f"Item not found in active items: {item_id}")
    return node


def get_item_status(item_node: ET.Element) -> str:
    return item_node.get("status", "")


def set_item_status(item_node: ET.Element, status: str) -> None:
    if status not in STATUS_VALUES:
        raise PlanManagerError(f"Unsupported status: {status}")
    item_node.set("status", status)


def ensure_result_block(item_node: ET.Element) -> ET.Element:
    return ensure_child(item_node, "r")


def set_result_text(item_node: ET.Element, field: str, value: str) -> None:
    result = ensure_result_block(item_node)
    set_or_create_text(result, field, value)


def ensure_files_block(parent: ET.Element, node_name: str) -> ET.Element:
    files = ensure_child(parent, node_name)
    ensure_child(files, "file")
    if len(files.findall("file")) == 1 and (files.find("file").text or "").strip() == "":
        files.remove(files.find("file"))
    return files


def set_file_list(parent: ET.Element, node_name: str, files: Iterable[str]) -> None:
    files_node = ensure_child(parent, node_name)
    for file_node in list(files_node.findall("file")):
        files_node.remove(file_node)
    for path in files:
        f = ET.SubElement(files_node, "file")
        f.text = path


def categorize_lesson(item_type: str, title: str, lesson: str) -> str:
    text = f"{item_type} {title} {lesson}".lower()
    if any(k in text for k in ["security", "auth", "threat", "vulnerability", "crypto", "access"]):
        return "Security"
    if any(k in text for k in ["test", "prove", "regression", "suite", "assert"]):
        return "Testing"
    if any(k in text for k in ["refactor", "module", "api", "architecture", "layer"]):
        return "Architecture"
    if any(k in text for k in ["workflow", "process", "sprint", "coordination"]):
        return "Process"
    return "Technology"


def parse_lessons_file(path: Path) -> tuple[str, dict[str, list[str]], int]:
    if not path.exists():
        skeleton = (
            "# Lessons Learned\n\n"
            f"> Auto-generated and maintained by the DA agent. Last updated: {today_str()}.\n\n"
            "## Technology\n\n"
            "## Architecture\n\n"
            "## Security\n\n"
            "## Testing\n\n"
            "## Process\n"
        )
        return skeleton, {
            "Technology": [],
            "Architecture": [],
            "Security": [],
            "Testing": [],
            "Process": [],
        }, 1

    content = path.read_text(encoding="utf-8")
    max_id = 0
    for match in re.findall(r"\*\*L-(\d+)\*\*", content):
        max_id = max(max_id, int(match))

    sections: dict[str, list[str]] = {
        "Technology": [],
        "Architecture": [],
        "Security": [],
        "Testing": [],
        "Process": [],
    }
    current = None
    for line in content.splitlines():
        m = re.match(r"^##\s+(Technology|Architecture|Security|Testing|Process)\s*$", line)
        if m:
            current = m.group(1)
            continue
        if current and line.strip().startswith("- **L-"):
            sections[current].append(line)
    return content, sections, max_id + 1


def write_lessons_file(path: Path, sections: dict[str, list[str]], date_text: str) -> None:
    lines = [
        "# Lessons Learned",
        "",
        f"> Auto-generated and maintained by the DA agent. Last updated: {date_text}.",
        "",
    ]
    for category in ["Technology", "Architecture", "Security", "Testing", "Process"]:
        lines.append(f"## {category}")
        lines.append("")
        lines.extend(sections[category])
        if sections[category]:
            lines.append("")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def ensure_security_concern(overview_root: ET.Element, title: str, description: str, mitigation: str) -> None:
    security = ensure_child(overview_root, "security")
    concern = ET.SubElement(security, "concern")
    set_or_create_text(concern, "title", title)
    set_or_create_text(concern, "description", description)
    set_or_create_text(concern, "mitigation", mitigation)


def create_item(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    archive_tree = parse_xml(paths.archive)
    plan_root = plan_tree.getroot()
    archive_root = archive_tree.getroot()

    items = ensure_child(plan_root, "items")
    archive_items = ensure_child(archive_root, "archive")
    item_id = str(next_numeric_item_id(items, archive_items))

    item_attrs = {
        "id": item_id,
        "type": args.kind,
        "status": "PENDING",
        "priority": args.priority,
        "complexity": args.complexity,
    }
    if args.security:
        item_attrs["security"] = "true"

    item = ET.SubElement(items, "item", item_attrs)
    set_or_create_text(item, "title", args.title)
    set_or_create_text(item, "justification", args.justification)
    set_or_create_text(item, "depends-on", args.depends_on or "")
    if args.parent:
        set_or_create_text(item, "parent", args.parent)
    if args.mapped_to_feature:
        set_or_create_text(item, "mapped-to-feature", args.mapped_to_feature)

    tasks = ensure_child(item, "tasks")
    for idx, task_text in enumerate(args.task or [], start=1):
        task = ET.SubElement(tasks, "task", {"id": f"{item_id}.{idx}"})
        task.text = task_text

    verification = ensure_child(item, "verification")
    tests = ensure_child(verification, "tests")
    if args.test_file:
        t = ET.SubElement(tests, "test", {"type": "focused"})
        set_file_list(t, "files", args.test_file)

    set_result_text(item, "outcome", "PENDING")
    set_result_text(item, "observations", "")
    set_result_text(item, "lessons-learned", "")
    set_file_list(ensure_result_block(item), "files", args.file or [])

    add_workflow_log(item, args.date, args.role, "created", "", "PENDING")

    append_changelog_entry(
        plan_root,
        args.date,
        f"Added {args.kind} item {item_id} (PENDING, {args.complexity}): {args.title}",
    )

    update_metadata_updated(plan_root, args.date)
    update_metadata_updated(archive_root, args.date)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)
        write_xml(archive_tree, paths.archive)

    return {"item_id": item_id, "status": "PENDING"}


def transition_item(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    overview_tree = parse_xml(paths.overview)
    plan_root = plan_tree.getroot()
    overview_root = overview_tree.getroot()

    items = ensure_child(plan_root, "items")
    item = find_item(items, args.item_id)

    from_status = get_item_status(item)
    to_status = args.to_status
    set_item_status(item, to_status)

    if to_status == "APPROVED" and not (item.findtext("branch") or "").strip():
        item_type = item.get("type", "feature")
        title = item.findtext("title", "item")
        set_or_create_text(item, "branch", branch_slug(item_type, args.item_id, title))

    if args.outcome:
        set_result_text(item, "outcome", args.outcome)
    if args.observations is not None:
        set_result_text(item, "observations", args.observations)
    if args.lessons_text is not None:
        set_result_text(item, "lessons-learned", args.lessons_text)
    if args.files:
        set_file_list(ensure_result_block(item), "files", args.files)

    action = args.action or args.to_status.lower()
    add_workflow_log(item, args.date, args.role, action, from_status, to_status)

    if args.to_status == "DENIED" and item.get("security") == "true":
        ensure_security_concern(
            overview_root,
            title=f"Denied security item {args.item_id}",
            description=item.findtext("title", "Security item denied"),
            mitigation="Item denied. Risk remains unmitigated until replacement work is approved.",
        )

    created_bug = None
    if args.create_followup_bug_title:
        created_bug = create_followup_bug(items, item, args)

    append_changelog_entry(
        plan_root,
        args.date,
        f"Item {args.item_id} status changed {from_status} -> {to_status}.",
    )

    update_metadata_updated(plan_root, args.date)
    update_metadata_updated(overview_root, args.date)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)
        write_xml(overview_tree, paths.overview)

    payload = {"item_id": args.item_id, "from": from_status, "to": to_status}
    if created_bug:
        payload["created_bug"] = created_bug
    return payload


def create_followup_bug(items_node: ET.Element, source_item: ET.Element, args: argparse.Namespace) -> str:
    max_id = 0
    for item in items_node.findall("item"):
        raw = item.get("id", "")
        if raw.isdigit():
            max_id = max(max_id, int(raw))
    bug_id = str(max_id + 1)
    bug = ET.SubElement(
        items_node,
        "item",
        {
            "id": bug_id,
            "type": "bug",
            "status": "PENDING",
            "priority": "HIGH",
            "complexity": "S",
        },
    )
    set_or_create_text(bug, "title", args.create_followup_bug_title)
    set_or_create_text(
        bug,
        "justification",
        f"Automatically created as follow-up for failed item {source_item.get('id')}",
    )
    set_or_create_text(bug, "depends-on", source_item.get("id", ""))
    add_workflow_log(bug, args.date, "TST", "created-followup", "", "PENDING")
    return bug_id


def item_has_active_dependents(items_node: ET.Element, item_id: str) -> bool:
    for other in items_node.findall("item"):
        if other.get("id") == item_id:
            continue
        status = other.get("status", "")
        if status in {"DONE", "DENIED", "ARCHIVED"}:
            continue
        deps = csv_to_ids(other.findtext("depends-on", ""))
        if item_id in deps:
            return True
    return False


def archive_run(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    archive_tree = parse_xml(paths.archive)
    overview_tree = parse_xml(paths.overview)

    plan_root = plan_tree.getroot()
    archive_root = archive_tree.getroot()
    overview_root = overview_tree.getroot()

    items = ensure_child(plan_root, "items")
    archive_items = ensure_child(archive_root, "archive")

    archived_ids: list[str] = []
    archived_done = 0
    archived_denied = 0
    blocked: list[str] = []

    lesson_content, lesson_sections, next_lesson_id = parse_lessons_file(paths.lessons)
    _ = lesson_content
    lesson_added: list[str] = []

    for item in list(items.findall("item")):
        item_id = item.get("id", "")
        status = item.get("status", "")
        if status not in {"DONE", "DENIED"}:
            continue
        if status == "DONE" and item_has_active_dependents(items, item_id):
            blocked.append(item_id)
            continue

        item.set("archived", args.date)
        add_workflow_log(item, args.date, args.role, "archived", status, "ARCHIVED")
        archive_items.append(copy.deepcopy(item))
        items.remove(item)
        archived_ids.append(item_id)
        if status == "DONE":
            archived_done += 1
            lesson = (item.findtext("r/lessons-learned", "") or "").strip()
            if lesson and lesson.lower() not in {"none", "n/a", "no special insights", "nothing notable"}:
                category = categorize_lesson(item.get("type", ""), item.findtext("title", ""), lesson)
                lid = f"L-{next_lesson_id}"
                next_lesson_id += 1
                line = f"- **{lid}** ({args.date}, item-{item_id}): {lesson}"
                lesson_sections[category].append(line)
                lesson_added.append(lid)

            add_completed_feature_from_item(overview_root, item, item_id, args.date)

        if status == "DENIED":
            archived_denied += 1

        if item.get("security") == "true":
            ensure_security_concern(
                overview_root,
                title=f"Archived security item {item_id}",
                description=item.findtext("title", ""),
                mitigation=f"Archived with status {status}. Review mitigation coverage in source item.",
            )

    metadata = ensure_child(plan_root, "metadata")
    done_counter_raw = metadata.findtext("done-since-last-fulltest", "0")
    try:
        done_counter = int(done_counter_raw)
    except ValueError:
        done_counter = 0
    done_counter += archived_done
    set_or_create_text(metadata, "done-since-last-fulltest", str(done_counter))

    append_changelog_entry(
        plan_root,
        args.date,
        "Archive run in progress.",
    )

    rotated = rotate_changelog(plan_root, archive_root, keep=30)
    changelog = ensure_child(plan_root, "changelog")
    latest_entry = changelog.find("entry")
    if latest_entry is not None:
        latest_entry.text = (
            f"Archive run: moved {len(archived_ids)} items (DONE: {archived_done}, DENIED: {archived_denied}); "
            f"lessons added: {', '.join(lesson_added) if lesson_added else 'none'}; "
            f"blocked: {', '.join(blocked) if blocked else 'none'}; rotated changelog entries: {rotated}."
        )

    update_metadata_updated(plan_root, args.date)
    update_metadata_updated(archive_root, args.date)
    update_metadata_updated(overview_root, args.date)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)
        write_xml(archive_tree, paths.archive)
        write_xml(overview_tree, paths.overview)
        write_lessons_file(paths.lessons, lesson_sections, args.date)

    return {
        "archived_ids": archived_ids,
        "archived_done": archived_done,
        "archived_denied": archived_denied,
        "blocked": blocked,
        "lessons": lesson_added,
        "rotated_changelog": rotated,
    }


def add_completed_feature_from_item(overview_root: ET.Element, item: ET.Element, item_id: str, date_text: str) -> None:
    completed = ensure_child(overview_root, "completed-features")
    existing = completed.find(f"feature[@id='CF-{item_id}']")
    if existing is not None:
        return

    feature = ET.SubElement(
        completed,
        "feature",
        {
            "id": f"CF-{item_id}",
            "completed": date_text,
            "completeness": "FULL",
            "test-coverage": "TESTED",
            "ref-item": item_id,
        },
    )
    set_or_create_text(feature, "title", item.findtext("title", f"Item {item_id}"))
    obs = (item.findtext("r/observations", "") or "").strip()
    set_or_create_text(feature, "description", obs[:400] if obs else "Completed via plan manager archival sync.")

    files = [f.text for f in item.findall("r/files/file") if (f.text or "").strip()]
    set_file_list(feature, "files", files)


def create_structural(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    plan_root = plan_tree.getroot()

    if args.kind == "sprint":
        container = ensure_child(plan_root, "sprints")
        sid = next_prefixed_id(plan_root, "sprints", "SPR")
        sprint = ET.SubElement(
            container,
            "sprint",
            {
                "id": sid,
                "status": args.status or "ACTIVE",
                "type": "SPRINT",
                "started": args.date,
            },
        )
        set_or_create_text(sprint, "title", args.title)
        scope = ensure_child(sprint, "scope")
        for item_id in args.scope_item or []:
            ref = ET.SubElement(scope, "item-ref", {"id": item_id, "type": "unknown", "status": "PENDING"})
            ref.text = f"Scope item {item_id}"
        gates = ensure_child(sprint, "gates")
        ET.SubElement(gates, "gate", {"name": "code-complete", "status": "PENDING", "date": "", "owner": "SM"})
        ET.SubElement(gates, "gate", {"name": "full-test-pass", "status": "PENDING", "date": "", "owner": "TST"})
        created_id = sid

    elif args.kind == "release":
        container = ensure_child(plan_root, "releases")
        rid = next_prefixed_id(plan_root, "releases", "REL")
        release = ET.SubElement(
            container,
            "release",
            {
                "id": rid,
                "status": args.status or "PLANNING",
                "type": args.release_type or "MINOR",
                "target-date": args.target_date or "",
            },
        )
        set_or_create_text(release, "title", args.title)
        scope = ensure_child(release, "scope")
        for item_id in args.scope_item or []:
            ET.SubElement(scope, "item-ref", {"id": item_id})
        gates = ensure_child(release, "gates")
        for gate_name in ["scope-freeze", "code-complete", "full-test-pass", "release-approval"]:
            ET.SubElement(gates, "gate", {"name": gate_name, "status": "PENDING", "date": ""})
        created_id = rid

    else:
        container = ensure_child(plan_root, "blockers")
        bid = next_prefixed_id(plan_root, "blockers", "BLK")
        blocker = ET.SubElement(
            container,
            "blocker",
            {
                "id": bid,
                "status": args.status or "ACTIVE",
                "severity": args.severity or "MEDIUM",
                "raised-by": args.role,
            },
        )
        set_or_create_text(blocker, "title", args.title)
        blocks = ensure_child(blocker, "blocks")
        for item_id in args.scope_item or []:
            ET.SubElement(blocks, "item-ref", {"id": item_id})
        set_or_create_text(blocker, "resolution-plan", args.resolution_plan or "")
        created_id = bid

    append_changelog_entry(plan_root, args.date, f"Added {args.kind} entry {created_id}: {args.title}")
    update_metadata_updated(plan_root, args.date)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)

    return {"id": created_id, "kind": args.kind}


def translate_requirement(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    plan_root = plan_tree.getroot()
    items = ensure_child(plan_root, "items")

    req = find_item(items, args.requirement_id)
    if req.get("type") != "requirement":
        raise PlanManagerError(f"Item {args.requirement_id} is not type=requirement")

    created: list[str] = []
    base = next_numeric_item_id(items)

    epic_id = str(base)
    epic = ET.SubElement(items, "item", {
        "id": epic_id,
        "type": "epic",
        "status": "PENDING",
        "priority": req.get("priority", "MEDIUM"),
        "complexity": "XL",
    })
    set_or_create_text(epic, "title", f"Epic from requirement {args.requirement_id}: {req.findtext('title', '')}")
    set_or_create_text(epic, "justification", "Auto-generated via translate command.")
    set_or_create_text(epic, "depends-on", args.requirement_id)
    created.append(epic_id)

    for i in range(args.features):
        fid = str(base + i + 1)
        feat = ET.SubElement(items, "item", {
            "id": fid,
            "type": "feature",
            "status": "PENDING",
            "priority": req.get("priority", "MEDIUM"),
            "complexity": "M",
        })
        set_or_create_text(feat, "title", f"Feature {i + 1} from requirement {args.requirement_id}")
        set_or_create_text(feat, "parent", epic_id)
        set_or_create_text(feat, "depends-on", epic_id)
        created.append(fid)

    append_changelog_entry(
        plan_root,
        args.date,
        f"Translated requirement {args.requirement_id} to epic {epic_id} and {args.features} feature items.",
    )
    update_metadata_updated(plan_root, args.date)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)

    return {"requirement": args.requirement_id, "created": created}


def init_overview_files(args: argparse.Namespace, paths: Paths) -> dict:
    # This command is intentionally conservative: initialize missing files only.
    created = []
    date_text = args.date

    if not paths.plan.exists():
        paths.plan.write_text(
            (
                "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                "<implementation-plan>\n"
                "  <metadata>\n"
                "    <title>ChordPro Feature and Bug Plan</title>\n"
                "    <version>3.1</version>\n"
                f"    <date>{date_text}</date>\n"
                f"    <updated>{date_text}</updated>\n"
                "    <status>Initialized by plan manager</status>\n"
                "    <summary>Initial skeleton</summary>\n"
                "    <done-since-last-fulltest>0</done-since-last-fulltest>\n"
                "    <last-fulltest-date></last-fulltest-date>\n"
                "  </metadata>\n"
                "  <items></items>\n"
                "  <sprints></sprints>\n"
                "  <releases></releases>\n"
                "  <blockers></blockers>\n"
                "  <changelog></changelog>\n"
                "</implementation-plan>\n"
            ),
            encoding="utf-8",
        )
        created.append(str(paths.plan))

    if not paths.archive.exists():
        paths.archive.write_text(
            (
                "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                "<plan-archive>\n"
                "  <metadata>\n"
                f"    <created>{date_text}</created>\n"
                f"    <updated>{date_text}</updated>\n"
                "    <source>overview-features-bugs.xml</source>\n"
                "  </metadata>\n"
                "  <archive></archive>\n"
                "  <changelog-history></changelog-history>\n"
                "</plan-archive>\n"
            ),
            encoding="utf-8",
        )
        created.append(str(paths.archive))

    if not paths.overview.exists():
        paths.overview.write_text(
            (
                "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                "<project-overview>\n"
                "  <metadata>\n"
                "    <title>ChordPro Project Overview</title>\n"
                "    <version>1.0</version>\n"
                f"    <updated>{date_text}</updated>\n"
                "  </metadata>\n"
                "  <security></security>\n"
                "  <completed-features></completed-features>\n"
                "</project-overview>\n"
            ),
            encoding="utf-8",
        )
        created.append(str(paths.overview))

    return {"created": created}


def sync_update(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    overview_tree = parse_xml(paths.overview)
    archive_tree = parse_xml(paths.archive)

    plan_root = plan_tree.getroot()
    overview_root = overview_tree.getroot()
    archive_root = archive_tree.getroot()

    update_metadata_updated(plan_root, args.date)
    update_metadata_updated(overview_root, args.date)
    update_metadata_updated(archive_root, args.date)

    append_changelog_entry(plan_root, args.date, args.summary or "Synchronization update executed.")
    rotated = rotate_changelog(plan_root, archive_root, keep=30)

    if not args.dry_run:
        write_xml(plan_tree, paths.plan)
        write_xml(overview_tree, paths.overview)
        write_xml(archive_tree, paths.archive)

    return {"rotated_changelog": rotated}


def security_update(args: argparse.Namespace, paths: Paths) -> dict:
    overview_tree = parse_xml(paths.overview)
    plan_tree = parse_xml(paths.plan)

    overview_root = overview_tree.getroot()
    plan_root = plan_tree.getroot()

    ensure_security_concern(overview_root, args.title, args.description, args.mitigation)
    update_metadata_updated(overview_root, args.date)

    append_changelog_entry(plan_root, args.date, f"Security update recorded: {args.title}")
    update_metadata_updated(plan_root, args.date)

    if not args.dry_run:
        write_xml(overview_tree, paths.overview)
        write_xml(plan_tree, paths.plan)

    return {"title": args.title}


def validate(args: argparse.Namespace, paths: Paths) -> dict:
    plan_tree = parse_xml(paths.plan)
    archive_tree = parse_xml(paths.archive)
    overview_tree = parse_xml(paths.overview)
    _ = overview_tree

    plan_root = plan_tree.getroot()
    archive_root = archive_tree.getroot()
    items = ensure_child(plan_root, "items")

    errors: list[str] = []
    warnings: list[str] = []

    ids_seen: set[str] = set()
    for item in items.findall("item"):
        iid = item.get("id", "")
        if iid in ids_seen:
            errors.append(f"Duplicate active item id: {iid}")
        ids_seen.add(iid)
        status = item.get("status", "")
        if status not in STATUS_VALUES:
            errors.append(f"Invalid status on item {iid}: {status}")

    for item in ensure_child(archive_root, "archive").findall("item"):
        iid = item.get("id", "")
        if iid in ids_seen:
            warnings.append(f"ID present in active and archive: {iid}")

    for item in items.findall("item"):
        iid = item.get("id", "")
        for dep in csv_to_ids(item.findtext("depends-on", "")):
            if not dep.isdigit():
                warnings.append(f"Item {iid} has non-numeric depends-on reference: {dep}")
                continue
            active = items.find(f"item[@id='{dep}']")
            archived = ensure_child(archive_root, "archive").find(f"item[@id='{dep}']")
            if active is None and archived is None:
                errors.append(f"Item {iid} depends on missing item {dep}")

    changelog = ensure_child(plan_root, "changelog")
    entry_count = len(changelog.findall("entry"))
    if entry_count > 30:
        warnings.append(f"Main changelog has {entry_count} entries (>30)")

    return {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "active_items": len(items.findall("item")),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="ChordPro plan XML manager")
    parser.add_argument("--plan", default="ai-docs/overview-features-bugs.xml")
    parser.add_argument("--archive", default="ai-docs/overview-features-bugs-archive.xml")
    parser.add_argument("--overview", default="ai-docs/overview.xml")
    parser.add_argument("--lessons", default="ai-docs/lessons-learned.md")
    parser.add_argument("--date", default=today_str())
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON output")
    parser.add_argument("--dry-run", action="store_true", help="Compute changes without writing files")

    sub = parser.add_subparsers(dest="cmd", required=True)

    p_create = sub.add_parser("create-item")
    p_create.add_argument("--kind", required=True, choices=["feature", "bug", "refactoring", "tech-debt", "epic", "enabler", "requirement", "security-item"]) 
    p_create.add_argument("--title", required=True)
    p_create.add_argument("--justification", default="")
    p_create.add_argument("--priority", default="MEDIUM")
    p_create.add_argument("--complexity", default="M")
    p_create.add_argument("--depends-on", default="")
    p_create.add_argument("--parent")
    p_create.add_argument("--mapped-to-feature")
    p_create.add_argument("--security", action="store_true")
    p_create.add_argument("--role", default="PO")
    p_create.add_argument("--task", action="append")
    p_create.add_argument("--test-file", action="append")
    p_create.add_argument("--file", action="append")

    p_trans = sub.add_parser("transition")
    p_trans.add_argument("--item-id", required=True)
    p_trans.add_argument("--to-status", required=True, choices=sorted(STATUS_VALUES))
    p_trans.add_argument("--role", default="PO")
    p_trans.add_argument("--action")
    p_trans.add_argument("--outcome")
    p_trans.add_argument("--observations")
    p_trans.add_argument("--lessons-text")
    p_trans.add_argument("--files", nargs="*")
    p_trans.add_argument("--create-followup-bug-title")

    p_archive = sub.add_parser("archive-run")
    p_archive.add_argument("--role", default="SM")

    p_struct = sub.add_parser("create-structural")
    p_struct.add_argument("--kind", required=True, choices=["sprint", "release", "blocker"])
    p_struct.add_argument("--title", required=True)
    p_struct.add_argument("--status")
    p_struct.add_argument("--scope-item", action="append")
    p_struct.add_argument("--release-type", choices=["PATCH", "MINOR", "MAJOR"])
    p_struct.add_argument("--target-date")
    p_struct.add_argument("--severity", choices=["LOW", "MEDIUM", "HIGH", "CRITICAL"])
    p_struct.add_argument("--resolution-plan")
    p_struct.add_argument("--role", default="SM")

    p_translate = sub.add_parser("translate")
    p_translate.add_argument("--requirement-id", required=True)
    p_translate.add_argument("--features", type=int, default=2)

    sub.add_parser("init-overview")

    p_sync = sub.add_parser("sync-update")
    p_sync.add_argument("--summary")

    p_sec = sub.add_parser("security-update")
    p_sec.add_argument("--title", required=True)
    p_sec.add_argument("--description", required=True)
    p_sec.add_argument("--mitigation", required=True)

    sub.add_parser("validate")

    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    paths = Paths(
        plan=Path(args.plan),
        archive=Path(args.archive),
        overview=Path(args.overview),
        lessons=Path(args.lessons),
    )

    try:
        if args.cmd == "create-item":
            result = create_item(args, paths)
        elif args.cmd == "transition":
            result = transition_item(args, paths)
        elif args.cmd == "archive-run":
            result = archive_run(args, paths)
        elif args.cmd == "create-structural":
            result = create_structural(args, paths)
        elif args.cmd == "translate":
            result = translate_requirement(args, paths)
        elif args.cmd == "init-overview":
            result = init_overview_files(args, paths)
        elif args.cmd == "sync-update":
            result = sync_update(args, paths)
        elif args.cmd == "security-update":
            result = security_update(args, paths)
        elif args.cmd == "validate":
            result = validate(args, paths)
        else:
            raise PlanManagerError(f"Unsupported command: {args.cmd}")

        if args.json:
            print(json.dumps({"ok": True, "command": args.cmd, "result": result}, ensure_ascii=True))
        else:
            print(f"OK {args.cmd}: {result}")
        return 0

    except PlanManagerError as exc:
        if args.json:
            print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=True))
        else:
            print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
