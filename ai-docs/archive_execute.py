#!/usr/bin/env python3
"""Execute archive run: move DONE items, extract lessons, rotate changelog, update metadata."""

import re
import os
from datetime import date

TODAY = "2026-03-04"
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# --- Read files ---
with open("overview-features-bugs.xml", "r") as f:
    active_xml = f.read()
with open("overview-features-bugs-archive.xml", "r") as f:
    archive_xml = f.read()
with open("overview.xml", "r") as f:
    overview_xml = f.read()

# --- Extract DONE items ---
# We need to find each DONE item block. Items are at indentation level "    <item"
# and end with "    </item>"
items_section_match = re.search(r'(<items>)(.*?)(</items>)', active_xml, re.DOTALL)
items_content = items_section_match.group(2)

# Split out individual items
item_blocks = re.findall(r'(    <item\s+id="(\d+)"[^>]*>.*?    </item>)', items_content, re.DOTALL)

done_items = []
remaining_items = []
for full_block, item_id in item_blocks:
    # Only check the opening <item> tag's status attribute, not internal workflow-log text
    opening_tag = re.match(r'    <item\s+[^>]*>', full_block)
    if opening_tag and 'status="DONE"' in opening_tag.group(0):
        done_items.append((item_id, full_block))
    else:
        remaining_items.append((item_id, full_block))

print(f"DONE items to archive: {len(done_items)} — IDs: {[x[0] for x in done_items]}")
print(f"Remaining items: {len(remaining_items)} — IDs: {[x[0] for x in remaining_items]}")

# --- Build new items section for active file ---
new_items_content = "\n"
for item_id, block in remaining_items:
    new_items_content += block + "\n\n"

# --- Build archived items to add to archive file ---
archived_additions = ""
for item_id, block in done_items:
    # Add archived attribute
    archived_block = re.sub(
        r'(<item\s+id="' + item_id + r'")',
        r'\1 archived="' + TODAY + r'"',
        block
    )
    archived_additions += "\n" + archived_block + "\n"

# --- Extract lessons-learned ---
lessons = []
lesson_id = 43

for item_id, item_xml in done_items:
    r_match = re.search(r'<r>\s*(.*?)\s*</r>', item_xml, re.DOTALL)
    if not r_match:
        continue
    r_content = r_match.group(1)
    ll_match = re.search(r'<lessons-learned>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</lessons-learned>', r_content, re.DOTALL)
    if not ll_match:
        continue
    lesson_text = ll_match.group(1).strip()
    if not lesson_text or lesson_text.lower() in ('none', 'n/a', ''):
        continue

    # Get title for category determination
    title_match = re.search(r'<title>(.*?)</title>', item_xml)
    title = title_match.group(1) if title_match else ""

    # Category
    if 'security' in title.lower() or 'security' in lesson_text.lower():
        category = "Security"
    elif any(w in lesson_text.lower() for w in ['assert', 'regression', 'suite', 'test should', 'fail criteria']):
        category = "Testing"
    elif any(w in lesson_text.lower() for w in ['debugger', 'process', 'workflow', 'debugging practice']):
        category = "Process"
    elif any(w in lesson_text.lower() for w in ['legacy backend', 'restricted-hash', 'variable shadow', 'config value']):
        category = "Technology"
    else:
        category = "Architecture"

    lessons.append({
        'id': f'L-{lesson_id}',
        'date': TODAY,
        'item_id': item_id,
        'text': lesson_text,
        'category': category,
    })
    lesson_id += 1

# --- Build CF entries for overview.xml ---
cf_entries_xml = ""
for item_id, item_xml in done_items:
    title_match = re.search(r'<title>(.*?)</title>', item_xml)
    title = title_match.group(1) if title_match else f"Item {item_id}"
    
    # Escape XML entities in title
    title = title.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    
    r_match = re.search(r'<r>\s*(.*?)\s*</r>', item_xml, re.DOTALL)
    obs_text = ""
    files_list = []
    if r_match:
        r_content = r_match.group(1)
        obs_match = re.search(r'<observations>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</observations>', r_content, re.DOTALL)
        if obs_match:
            obs_text = obs_match.group(1).strip()
            # Truncate for description
            if len(obs_text) > 300:
                obs_text = obs_text[:297] + "..."
        files_match = re.search(r'<files>(.*?)</files>', r_content, re.DOTALL)
        if files_match:
            files_list = re.findall(r'<file>(.*?)</file>', files_match.group(1))

    # Also check <result> block  
    if not obs_text:
        result_match = re.search(r'<result[^>]*>\s*(.*?)\s*</result>', item_xml, re.DOTALL)
        if result_match:
            sum_match = re.search(r'<summary>\s*(?:<!\[CDATA\[)?\s*(.*?)\s*(?:\]\]>)?\s*</summary>', result_match.group(1), re.DOTALL)
            if sum_match:
                obs_text = sum_match.group(1).strip()
                if len(obs_text) > 300:
                    obs_text = obs_text[:297] + "..."

    if not obs_text:
        obs_text = title

    # Escape XML in description  
    obs_text = obs_text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    files_xml = ""
    for f in files_list[:5]:
        files_xml += f"\n        <file>{f}</file>"

    cf_entries_xml += f"""
    <feature id="CF-{item_id}" completed="{TODAY}" source-item="{item_id}">
      <title>{title}</title>
      <description>{obs_text}</description>
      <files>{files_xml}
      </files>
    </feature>"""

# --- Changelog rotation ---
changelog_match = re.search(r'<changelog>\s*(.*?)\s*</changelog>', active_xml, re.DOTALL)
changelog_content = changelog_match.group(1)
entries = re.findall(r'(<entry\s+date="[^"]*">.*?</entry>)', changelog_content, re.DOTALL)

# Add archive entry
archive_entry = f"""    <entry date="{TODAY}">Archive run: moved {len(done_items)} DONE items ({', '.join([x[0] for x in done_items])}) to overview-features-bugs-archive.xml. Extracted {len(lessons)} lessons (L-43 through L-{42 + len(lessons)}) to ai-docs/lessons-learned.md. Added {len(done_items)} completed-feature entries to overview.xml. Rotated {max(0, len(entries) - 29)} oldest changelog entries to archive history. Updated done-since-last-fulltest counter by {len(done_items)}.</entry>"""

# New changelog: archive entry + keep 29 most recent (total 30)
keep_count = 29  # 29 old + 1 new = 30
keep_entries = entries[:keep_count]
move_entries = entries[keep_count:]

new_changelog = f"\n{archive_entry}\n"
for e in keep_entries:
    new_changelog += f"    {e}\n"

# --- Apply changes to active file ---
# 1. Replace items section
new_active = active_xml.replace(
    items_section_match.group(0),
    f"<items>{new_items_content}  </items>"
)

# 2. Replace changelog
new_active = re.sub(
    r'<changelog>\s*.*?\s*</changelog>',
    f'<changelog>\n{new_changelog}  </changelog>',
    new_active,
    flags=re.DOTALL
)

# 3. Update metadata
new_active = re.sub(
    r'<done-since-last-fulltest>\d+</done-since-last-fulltest>',
    f'<done-since-last-fulltest>{len(done_items)}</done-since-last-fulltest>',
    new_active
)
new_active = re.sub(
    r'(<metadata>.*?<updated>)[^<]*(</updated>)',
    rf'\g<1>{TODAY}\2',
    new_active,
    count=1,
    flags=re.DOTALL
)

# --- Apply changes to archive file ---
# Insert archived items before </archive>
new_archive = archive_xml.replace(
    '  </archive>  <!-- end archive -->',
    f'{archived_additions}\n  </archive>  <!-- end archive -->'
)

# Add rotated changelog entries to changelog-history
move_entries_xml = ""
for e in move_entries:
    move_entries_xml += f"    {e}\n"

new_archive = new_archive.replace(
    '  </changelog-history>',
    f'{move_entries_xml}  </changelog-history>'
)

# Update archive metadata
new_archive = re.sub(
    r'(<metadata>.*?<updated>)[^<]*(</updated>)',
    rf'\g<1>{TODAY}\2',
    new_archive,
    count=1,
    flags=re.DOTALL
)

# --- Apply changes to overview.xml ---
# Add CF entries before </completed-features>
new_overview = overview_xml.replace(
    '  </completed-features>',
    f'{cf_entries_xml}\n  </completed-features>'
)

# Update overview metadata
new_overview = re.sub(
    r'(<metadata>.*?<updated>)[^<]*(</updated>)',
    rf'\g<1>{TODAY}\2',
    new_overview,
    count=1,
    flags=re.DOTALL
)

# --- Build lessons-learned additions ---
with open("lessons-learned.md", "r") as f:
    lessons_md = f.read()

# Group lessons by category
cat_additions = {}
for l in lessons:
    cat = l['category']
    if cat not in cat_additions:
        cat_additions[cat] = []
    cat_additions[cat].append(l)

# Map German category headers used in the file
cat_headers = {
    'Technology': '## Technologie',
    'Architecture': '## Architektur', 
    'Security': '## Security',
    'Testing': '## Testing',
    'Process': '## Process',
}

for cat, cat_lessons in cat_additions.items():
    header = cat_headers.get(cat, f'## {cat}')
    additions = ""
    for l in cat_lessons:
        # Clean up lesson text for markdown
        text = l['text'].replace('\n', ' ').strip()
        additions += f"\n- **{l['id']}** ({l['date']}, item-{l['item_id']}): {text}"
    
    # Find the section and append
    if header in lessons_md:
        # Find the end of the section (next ## or end of file)
        section_start = lessons_md.index(header) + len(header)
        # Find next section header
        next_header = re.search(r'\n## ', lessons_md[section_start:])
        if next_header:
            insert_pos = section_start + next_header.start()
        else:
            insert_pos = len(lessons_md)
        
        # Insert before the next section
        lessons_md = lessons_md[:insert_pos] + additions + "\n" + lessons_md[insert_pos:]

# Update the "Last updated" date
lessons_md = re.sub(
    r'Last updated: \d{4}-\d{2}-\d{2}',
    f'Last updated: {TODAY}',
    lessons_md
)

# --- Write all files ---
with open("overview-features-bugs.xml", "w") as f:
    f.write(new_active)
print("Written: overview-features-bugs.xml")

with open("overview-features-bugs-archive.xml", "w") as f:
    f.write(new_archive)
print("Written: overview-features-bugs-archive.xml")

with open("overview.xml", "w") as f:
    f.write(new_overview)
print("Written: overview.xml")

with open("lessons-learned.md", "w") as f:
    f.write(lessons_md)
print("Written: lessons-learned.md")

# --- Final report ---
print(f"\n{'='*60}")
print(f"ARCHIVE RUN COMPLETE — {TODAY}")
print(f"{'='*60}")
print(f"Items archived: {len(done_items)}")
print(f"  IDs: {', '.join([x[0] for x in done_items])}")
print(f"Lessons extracted: {len(lessons)}")
for l in lessons:
    print(f"  {l['id']} ({l['category']}, item-{l['item_id']})")
print(f"CF entries added to overview.xml: {len(done_items)}")
print(f"Changelog entries rotated to archive: {len(move_entries)}")
print(f"Remaining items in active file: {len(remaining_items)}")
print(f"  IDs: {', '.join([x[0] for x in remaining_items])}")
print(f"done-since-last-fulltest: {len(done_items)}")
print(f"last-fulltest-date: 2026-03-03")

# Full-test trigger check
counter = len(done_items)
last_ft = "2026-03-03"
trigger_reasons = []
if counter >= 5:
    trigger_reasons.append(f"counter={counter} >= 5")

if trigger_reasons:
    print(f"\n*** FULL-TEST RECOMMENDATION ***")
    print(f"  {counter} items archived since last full test (last: {last_ft}).")
    print(f"  Recommendation: run /full-test to validate overall project quality.")
    print(f"  Trigger: {'; '.join(trigger_reasons)}")

print(f"\nItems NOT archived:")
for item_id, block in remaining_items:
    status_match = re.search(r'status="(\w+)"', block)
    status = status_match.group(1) if status_match else "?"
    title_match = re.search(r'<title>(.*?)</title>', block)
    title = title_match.group(1) if title_match else "?"
    print(f"  Item {item_id} [{status}]: {title}")
