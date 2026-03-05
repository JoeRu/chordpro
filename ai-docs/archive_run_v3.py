#!/usr/bin/env python3
"""
Archive run script for ChordPro implementation plan.
Moves 12 DONE items (53, 60-70) from active plan to archive.
Date: 2026-03-04
"""
import re
import sys
from datetime import date

TODAY = "2026-03-04"
DONE_IDS = {53, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70}
MAX_CHANGELOG = 30

# === STEP 1: Read all files ===
print("=== Reading files ===")
with open("overview-features-bugs.xml", "r") as f:
    active_content = f.read()
with open("overview-features-bugs-archive.xml", "r") as f:
    archive_content = f.read()
with open("overview.xml", "r") as f:
    overview_content = f.read()
with open("lessons-learned.md", "r") as f:
    lessons_content = f.read()

# === STEP 2: Extract item blocks from active plan ===
print("=== Extracting DONE items ===")

# Find all item blocks: <item id="N" ...>...</item>
# Use non-greedy match within items section
items_match = re.search(r'(<items>)(.*?)(</items>)', active_content, re.DOTALL)
if not items_match:
    print("ERROR: Could not find <items> section")
    sys.exit(1)

items_section = items_match.group(2)

# Extract individual item blocks
item_pattern = re.compile(r'(    <item id="(\d+)"[^>]*>.*?</item>)', re.DOTALL)
items_found = []
items_to_archive = []
items_to_keep = []

for m in item_pattern.finditer(items_section):
    full_block = m.group(1)
    item_id = int(m.group(2))
    
    # Check status ONLY in the opening tag (first line)
    opening_tag = full_block[:full_block.index('>')]
    status_match = re.search(r'status="(\w+)"', opening_tag)
    status = status_match.group(1) if status_match else "UNKNOWN"
    
    items_found.append((item_id, status))
    
    if item_id in DONE_IDS and status == "DONE":
        items_to_archive.append((item_id, full_block))
    else:
        items_to_keep.append((item_id, full_block))

print(f"  Found {len(items_found)} items total")
print(f"  Archiving: {sorted([i for i,_ in items_to_archive])}")
print(f"  Keeping: {sorted([i for i,_ in items_to_keep])}")

if len(items_to_archive) != 12:
    print(f"WARNING: Expected 12 items to archive, found {len(items_to_archive)}")
    missing = DONE_IDS - {i for i, _ in items_to_archive}
    if missing:
        print(f"  Missing IDs: {sorted(missing)}")

# === STEP 3: Extract lessons from archived items ===
print("=== Extracting lessons ===")

# Get current max lesson ID
lesson_ids = re.findall(r'\*\*L-(\d+)\*\*', lessons_content)
next_lesson_id = max(int(x) for x in lesson_ids) + 1 if lesson_ids else 1
print(f"  Next lesson ID: L-{next_lesson_id}")

# Lesson data per item (extracted from subagent analysis)
lessons_data = {
    # item_id: (category, lesson_text)
    60: ("Architecture", "Barline geometry from shared row-independent model; compact connected-pair styling asserted via arrow-stem geometry."),
    61: ("Architecture", "Normalize token semantics before rendering; shared decoration helpers reduce drift."),
    62: None,  # Uses <result> block, no <r><lessons-learned>
    63: ("Architecture", "Row-type-aware column counting is the correct abstraction: strumline = beats (1 column), gridline = individual chords (N columns)."),
    64: ("Architecture", "Semantic preservation and geometry normalization must remain separate concerns. Renderer-level handling safer than globally deleting in shared normalization."),
    65: ("Architecture", "Facade + internal module split reduces change risk while keeping external call-sites stable."),
    66: ("Process", "Debugger-specific friction handled with local debugging practices, not by expanding public setter APIs."),
    67: ("Architecture", "Namespace/path refactors safest with compatibility shim retained during migration."),
    68: ("Architecture", "Centralizing asset preparation simplifies downstream element handling."),
    69: ("Technology", "Legacy backends should normalize restricted-hash data into plain hashes before applying defaults."),
    70: ("Technology", "Delegate helpers relying on module-scoped state should avoid local variable shadowing and guard backend-key access defensively."),
}
# Item 53 has no <r> block and no lessons

new_lessons = []  # (category, text)
for item_id in sorted(DONE_IDS):
    data = lessons_data.get(item_id)
    if data is None:
        print(f"  Item {item_id}: no lessons (skipped)")
        continue
    category, text = data
    lid = f"L-{next_lesson_id}"
    new_lessons.append((lid, category, item_id, text))
    print(f"  {lid} ({category}, item-{item_id})")
    next_lesson_id += 1

# === STEP 4: Build completed-features entries for overview.xml ===
print("=== Building completed-features entries ===")

cf_entries = []
for item_id, block in items_to_archive:
    # Extract title
    title_m = re.search(r'<title>(.*?)</title>', block, re.DOTALL)
    title = title_m.group(1).strip() if title_m else f"Item {item_id}"
    
    # Extract observations/description from <r> block or <result> block
    desc = ""
    r_match = re.search(r'<observations>(.*?)</observations>', block, re.DOTALL)
    if r_match:
        desc = r_match.group(1).strip()
    else:
        result_match = re.search(r'<result[^>]*>(.*?)</result>', block, re.DOTALL)
        if result_match:
            summary_m = re.search(r'<summary>(.*?)</summary>', result_match.group(1), re.DOTALL)
            if summary_m:
                desc = summary_m.group(1).strip()
    
    # Extract files from <r> block
    files = []
    r_block = re.search(r'<r>(.*?)</r>', block, re.DOTALL)
    if r_block:
        file_matches = re.findall(r'<file>(.*?)</file>', r_block.group(1))
        files = [f for f in file_matches if not f.endswith('.xml')]  # skip xml plan files
    
    # Get completion date from workflow-log last DONE entry
    comp_date = TODAY
    wf_dates = re.findall(r'timestamp="(\d{4}-\d{2}-\d{2})"[^>]*to-status="DONE"', block)
    if wf_dates:
        comp_date = wf_dates[-1]
    
    cf_entry = f'    <feature id="CF-{item_id}" completed="{comp_date}" source-item="{item_id}">\n'
    cf_entry += f'      <title>{title}</title>\n'
    if desc:
        # Escape any XML special chars in description
        desc_escaped = desc.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        # But preserve CDATA if present
        if '![CDATA[' in desc:
            cf_entry += f'      <description><![CDATA[{desc}]]></description>\n'
        else:
            cf_entry += f'      <description>{desc_escaped}</description>\n'
    cf_entry += '      <files>\n'
    for f in files:
        cf_entry += f'        <file>{f}</file>\n'
    cf_entry += '      </files>\n'
    cf_entry += '    </feature>'
    cf_entries.append(cf_entry)
    print(f"  CF-{item_id}: {title[:60]}...")

# === STEP 5: Rebuild active plan with items removed ===
print("=== Rebuilding active plan ===")

# Build new items section with only kept items
new_items_content = "\n"
for item_id, block in items_to_keep:
    new_items_content += block + "\n\n"

new_items_section = f"  <items>{new_items_content}  </items>"

# Replace the items section
new_active = active_content[:items_match.start()] + new_items_section + active_content[items_match.end():]

# === STEP 6: Handle changelog rotation ===
print("=== Rotating changelog ===")

changelog_match = re.search(r'<changelog>\n(.*?)</changelog>', new_active, re.DOTALL)
if changelog_match:
    entries_text = changelog_match.group(1)
    # Split into individual entries
    entry_pattern = re.compile(r'(    <entry date="[^"]*">.*?</entry>)', re.DOTALL)
    all_entries = entry_pattern.findall(entries_text)
    print(f"  Found {len(all_entries)} changelog entries")
    
    if len(all_entries) > MAX_CHANGELOG:
        keep_entries = all_entries[:MAX_CHANGELOG]  # Most recent (first in file = newest)
        rotate_entries = all_entries[MAX_CHANGELOG:]  # Oldest (last in file)
        print(f"  Keeping {len(keep_entries)}, rotating {len(rotate_entries)} to archive")
    else:
        keep_entries = all_entries
        rotate_entries = []
        print(f"  No rotation needed ({len(all_entries)} <= {MAX_CHANGELOG})")
    
    # Add the archive run entry as newest
    archive_entry = f'    <entry date="{TODAY}">Archive run executed: moved {len(items_to_archive)} items to overview-features-bugs-archive.xml (DONE: {len(items_to_archive)}, DENIED: 0). Archived IDs: {", ".join(str(i) for i,_ in items_to_archive)}. Extracted lessons L-{new_lessons[0][0].split("-")[1]} through L-{new_lessons[-1][0].split("-")[1]} to lessons-learned.md. Updated overview completed-features for source items {", ".join(str(i) for i,_ in items_to_archive)}; done-since-last-fulltest={len(items_to_archive)}.</entry>'
    
    # new changelog = archive entry + kept entries (drop last if we'd exceed 30 with new entry)
    new_changelog_entries = [archive_entry] + keep_entries
    if len(new_changelog_entries) > MAX_CHANGELOG:
        # Move extra to rotation
        extra = new_changelog_entries[MAX_CHANGELOG:]
        rotate_entries = extra + rotate_entries
        new_changelog_entries = new_changelog_entries[:MAX_CHANGELOG]
    
    new_changelog = "  <changelog>\n" + "\n".join(new_changelog_entries) + "\n</changelog>"
    new_active = new_active[:changelog_match.start() - 2] + new_changelog + new_active[changelog_match.end():]
else:
    rotate_entries = []
    print("  WARNING: No changelog section found")

# === STEP 7: Update metadata in active plan ===
print("=== Updating active plan metadata ===")

# Update done-since-last-fulltest
new_active = re.sub(
    r'<done-since-last-fulltest>\d+</done-since-last-fulltest>',
    f'<done-since-last-fulltest>{len(items_to_archive)}</done-since-last-fulltest>',
    new_active
)

# Update updated date
new_active = re.sub(
    r'(<metadata>.*?)<updated>[^<]+</updated>',
    f'\\1<updated>{TODAY}</updated>',
    new_active,
    count=1,
    flags=re.DOTALL
)

# === STEP 8: Add items to archive file ===
print("=== Adding items to archive ===")

archive_items_text = ""
for item_id, block in items_to_archive:
    # Add archived="TODAY" attribute to the opening tag
    archived_block = re.sub(
        r'(<item id="\d+"[^>]*)(>)',
        f'\\1 archived="{TODAY}"\\2',
        block,
        count=1
    )
    archive_items_text += "\n" + archived_block + "\n"

# Insert before </archive>
new_archive = archive_content.replace(
    '  </archive>  <!-- end archive -->',
    archive_items_text + '\n  </archive>  <!-- end archive -->'
)

# Add rotated changelog entries to changelog-history
if rotate_entries:
    rotated_text = "\n".join(rotate_entries)
    new_archive = new_archive.replace(
        '  </changelog-history>',
        rotated_text + '\n  </changelog-history>'
    )

# Update archive metadata date
new_archive = re.sub(
    r'(<metadata>.*?)<updated>[^<]+</updated>',
    f'\\1<updated>{TODAY}</updated>',
    new_archive,
    count=1,
    flags=re.DOTALL
)

# === STEP 9: Update overview.xml ===
print("=== Updating overview.xml ===")

# Add completed-features entries
cf_text = "\n".join(cf_entries)
new_overview = overview_content.replace(
    '  </completed-features>',
    cf_text + '\n  </completed-features>'
)

# Handle security item 68
# Item 68 is an asset preparation pipeline feature - add a security note
security_note = '''    <concern>
      <title>Pre-render asset pipeline path traversal</title>
      <description>The HTML5 pre-render asset preparation pipeline (item 68) processes image paths for embedding. Improperly validated paths could enable path traversal or arbitrary file inclusion.</description>
      <mitigation>Item 68 implemented image-first embedding contract with restricted fast-path limited to delegate/SVG assets; element-level opts preserved for prepared assets. Concern considered mitigated.</mitigation>
    </concern>'''

new_overview = new_overview.replace(
    '  </security>',
    security_note + '\n  </security>'
)

# Update overview metadata date
new_overview = re.sub(
    r'(<metadata>.*?)<updated>[^<]+</updated>',
    f'\\1<updated>{TODAY}</updated>',
    new_overview,
    count=1,
    flags=re.DOTALL
)

# === STEP 10: Update lessons-learned.md ===
print("=== Updating lessons-learned.md ===")

# Group lessons by category
by_category = {}
for lid, category, item_id, text in new_lessons:
    if category not in by_category:
        by_category[category] = []
    by_category[category].append((lid, item_id, text))

# Map categories to section headers in the file
category_map = {
    "Technology": "## Technologie",
    "Architecture": "## Architektur", 
    "Security": "## Security",
    "Testing": "## Testing",
    "Process": "## Process",
}

new_lessons_content = lessons_content
for category, entries in by_category.items():
    section_header = category_map.get(category, f"## {category}")
    
    # Find all content under this section header until the next ## header
    section_pattern = re.compile(
        rf'({re.escape(section_header)}\n)(.*?)(?=\n## |\Z)',
        re.DOTALL
    )
    match = section_pattern.search(new_lessons_content)
    if match:
        existing = match.group(2)
        additions = "\n".join(
            f"- **{lid}** ({TODAY}, item-{item_id}): {text}"
            for lid, item_id, text in entries
        )
        new_section = match.group(1) + existing.rstrip() + "\n" + additions + "\n"
        new_lessons_content = new_lessons_content[:match.start()] + new_section + new_lessons_content[match.end():]

# === STEP 11: Write all files ===
print("=== Writing files ===")

with open("overview-features-bugs.xml", "w") as f:
    f.write(new_active)
print(f"  overview-features-bugs.xml written")

with open("overview-features-bugs-archive.xml", "w") as f:
    f.write(new_archive)
print(f"  overview-features-bugs-archive.xml written")

with open("overview.xml", "w") as f:
    f.write(new_overview)
print(f"  overview.xml written")

with open("lessons-learned.md", "w") as f:
    f.write(new_lessons_content)
print(f"  lessons-learned.md written")

# === STEP 12: Summary ===
print("\n=== ARCHIVE RUN SUMMARY ===")
print(f"Date: {TODAY}")
print(f"Items archived: {len(items_to_archive)} (IDs: {', '.join(str(i) for i,_ in items_to_archive)})")
print(f"Items remaining: {len(items_to_keep)} (IDs: {', '.join(str(i) for i,_ in items_to_keep)})")
print(f"Lessons extracted: {len(new_lessons)} ({new_lessons[0][0]} through {new_lessons[-1][0]})")
print(f"CF entries added: {len(cf_entries)}")
print(f"Changelog entries rotated: {len(rotate_entries)}")
print(f"Security concern added for item 68: yes")
print(f"done-since-last-fulltest updated to: {len(items_to_archive)}")

# Full-test trigger check
counter = len(items_to_archive)
last_fulltest = "2026-03-03"
print(f"\n=== FULL-TEST TRIGGER CHECK ===")
print(f"Counter: {counter} (threshold: 5)")
print(f"Last full-test: {last_fulltest}")
if counter >= 5:
    print(f"TRIGGERED: {counter} items archived since last full test (last: {last_fulltest}). Recommendation: run /full-test to validate overall project quality.")
