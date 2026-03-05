#!/usr/bin/env python3
"""Archive run script for overview-features-bugs.xml.
Moves DONE items to archive, extracts lessons, rotates changelog."""

import re
import sys
from datetime import date

TODAY = "2026-03-04"

# --- Step 1: Read files ---
with open("overview-features-bugs.xml", "r") as f:
    active_xml = f.read()

with open("overview-features-bugs-archive.xml", "r") as f:
    archive_xml = f.read()

with open("overview.xml", "r") as f:
    overview_xml = f.read()

# --- Step 2: Identify DONE items ---
# Find all item elements with status="DONE"
item_pattern = re.compile(
    r'(    <item\s+id="(\d+)"[^>]*status="DONE"[^>]*>.*?</item>)',
    re.DOTALL
)

done_items = []
for match in item_pattern.finditer(active_xml):
    item_xml = match.group(1)
    item_id = match.group(2)
    done_items.append((item_id, item_xml))

# Items that should NOT be archived (active items that might depend on them)
# Check: item 73 is IN_PROGRESS - does it depend on any DONE item?
# From the file: item 73 has no depends-on. Items 26-32 depend on 26,27,28,29 only.
# So all DONE items are eligible.

print(f"Found {len(done_items)} DONE items: {[x[0] for x in done_items]}")

# --- Step 3: Extract lessons-learned from each item ---
lessons = []
lesson_id = 43  # Next available after L-42

for item_id, item_xml in done_items:
    # Look for <r>...<lessons-learned>...</lessons-learned>...</r> or
    # <lessons-learned> inside <r> block
    r_match = re.search(r'<r>\s*(.*?)\s*</r>', item_xml, re.DOTALL)
    if not r_match:
        # Also check for <result> block
        continue
    
    r_content = r_match.group(1)
    ll_match = re.search(r'<lessons-learned>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</lessons-learned>', r_content, re.DOTALL)
    if not ll_match:
        continue
    
    lesson_text = ll_match.group(1).strip()
    if not lesson_text or lesson_text.lower() in ('none', 'n/a', ''):
        continue
    if any(skip in lesson_text.lower() for skip in ['no special insights', 'nothing notable']):
        continue
    
    # Determine category based on item type and content
    item_type_match = re.search(r'type="(\w+)"', item_xml)
    item_type = item_type_match.group(1) if item_type_match else "feature"
    title_match = re.search(r'<title>(.*?)</title>', item_xml)
    title = title_match.group(1) if title_match else ""
    
    # Split multi-sentence lessons into separate entries if they contain distinct concepts
    # For simplicity, keep as single entry per item
    
    # Category determination
    if 'security' in title.lower() or 'security' in lesson_text.lower():
        category = "Security"
    elif 'test' in lesson_text.lower() and ('assert' in lesson_text.lower() or 'regression' in lesson_text.lower() or 'suite' in lesson_text.lower()):
        category = "Testing"
    elif any(w in lesson_text.lower() for w in ['architect', 'facade', 'module', 'namespace', 'geometry', 'normalization', 'rendering', 'column', 'layout', 'semantic', 'centrali']):
        category = "Architecture"
    elif any(w in lesson_text.lower() for w in ['debugger', 'process', 'workflow']):
        category = "Process"
    else:
        category = "Technology"
    
    lessons.append({
        'id': f'L-{lesson_id}',
        'date': TODAY,
        'item_id': item_id,
        'text': lesson_text,
        'category': category,
    })
    lesson_id += 1

print(f"\nExtracted {len(lessons)} lessons:")
for l in lessons:
    print(f"  {l['id']} ({l['category']}, item-{l['item_id']}): {l['text'][:80]}...")

# --- Step 4: Build archived items XML ---
archived_items_xml = ""
for item_id, item_xml in done_items:
    # Add archived attribute
    archived_item = re.sub(
        r'(<item\s+id="' + item_id + r'")',
        rf'\1 archived="{TODAY}"',
        item_xml
    )
    archived_items_xml += "\n" + archived_item + "\n"

# --- Step 5: Build completed-features entries for overview.xml ---
cf_entries = []
for item_id, item_xml in done_items:
    title_match = re.search(r'<title>(.*?)</title>', item_xml)
    title = title_match.group(1) if title_match else f"Item {item_id}"
    
    # Get description from observations or summary
    r_match = re.search(r'<r>\s*(.*?)\s*</r>', item_xml, re.DOTALL)
    obs_text = ""
    files_list = []
    if r_match:
        r_content = r_match.group(1)
        obs_match = re.search(r'<observations>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</observations>', r_content, re.DOTALL)
        if obs_match:
            obs_text = obs_match.group(1).strip()[:200]
        # Get files
        files_match = re.search(r'<files>(.*?)</files>', r_content, re.DOTALL)
        if files_match:
            files_list = re.findall(r'<file>(.*?)</file>', files_match.group(1))
    
    # Also check <result> block for item 62
    if not obs_text:
        result_match = re.search(r'<result[^>]*>\s*(.*?)\s*</result>', item_xml, re.DOTALL)
        if result_match:
            sum_match = re.search(r'<summary>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</summary>', result_match.group(1), re.DOTALL)
            if sum_match:
                obs_text = sum_match.group(1).strip()[:200]
    
    if not obs_text:
        obs_text = title
    
    files_xml = ""
    for f in files_list[:5]:  # Limit to 5 files
        files_xml += f"\n        <file>{f}</file>"
    
    cf_entry = f"""    <feature id="CF-{item_id}" completed="{TODAY}" source-item="{item_id}">
      <title>{title}</title>
      <description>{obs_text}</description>
      <files>{files_xml}
      </files>
    </feature>"""
    cf_entries.append(cf_entry)

# --- Step 6: Handle changelog rotation ---
# Find all changelog entries in active file
changelog_match = re.search(r'<changelog>\s*(.*?)\s*</changelog>', active_xml, re.DOTALL)
if changelog_match:
    changelog_content = changelog_match.group(1)
    entries = re.findall(r'(<entry\s+date="[^"]*">.*?</entry>)', changelog_content, re.DOTALL)
    print(f"\nChangelog entries: {len(entries)}")
    
    if len(entries) > 30:
        # Keep 30 most recent (entries appear newest-first in the file)
        keep_entries = entries[:30]
        move_entries = entries[30:]
        print(f"  Keeping {len(keep_entries)}, moving {len(move_entries)} to archive history")
    else:
        keep_entries = entries
        move_entries = []
else:
    keep_entries = []
    move_entries = []

# --- Step 7: Build lessons-learned additions ---
lessons_by_category = {}
for l in lessons:
    cat = l['category']
    if cat not in lessons_by_category:
        lessons_by_category[cat] = []
    lessons_by_category[cat].append(l)

# --- Output summary ---
print(f"\n=== Archive Run Summary ===")
print(f"Items to archive: {len(done_items)}")
print(f"Lessons extracted: {len(lessons)}")
print(f"Changelog entries to rotate: {len(move_entries)}")
print(f"CF entries to add: {len(cf_entries)}")

# Write the data we need for the actual file edits
with open("archive_data.txt", "w") as f:
    f.write("=== ARCHIVED ITEMS XML ===\n")
    f.write(archived_items_xml)
    f.write("\n\n=== CF ENTRIES ===\n")
    for cf in cf_entries:
        f.write(cf + "\n")
    f.write("\n\n=== LESSONS ===\n")
    for l in lessons:
        f.write(f"{l['id']}|{l['date']}|{l['item_id']}|{l['category']}|{l['text']}\n")
    f.write("\n\n=== MOVE CHANGELOG ENTRIES ===\n")
    for e in move_entries:
        f.write(e + "\n")
    f.write("\n\n=== KEEP CHANGELOG ENTRIES ===\n")
    for e in keep_entries:
        f.write(e + "\n")
    f.write(f"\n\n=== ITEM IDS ===\n")
    f.write(",".join([x[0] for x in done_items]))

print("\nData written to archive_data.txt")
print("Now apply file edits manually.")
