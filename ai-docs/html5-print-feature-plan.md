# HTML5 Print Feature: Gap Analysis & Implementation Plan

## Executive Summary

The HTML5 backend has a solid foundation (template-driven architecture, CSS variable system, basic song rendering) but is missing significant features compared to the PDF backend. The "paged mode" infrastructure (templates, FormatGenerator, CSS @page rules) exists but is never activated — making it the single most impactful fix. Beyond paged mode, the main gaps are: chorus recall, delegate support (ABC/LilyPond), grid rendering fidelity, image alignment, comment_box styling, section label display, chord diagram positioning, annotations, keyboard diagrams, and chords-under/inline-chords modes.

---

## Feature Gap Inventory

| # | Feature | PDF | HTML5 | Gap |
|---|---------|-----|-------|-----|
| 1 | Paged mode activation | N/A | Templates exist, never selected | CRITICAL |
| 2 | Headers/footers with metadata | Full 3-part format | FormatGenerator exists, never called | CRITICAL |
| 3 | Page numbering | Roman + Arabic | FormatGenerator has code, dead | CRITICAL |
| 4 | Odd/even page differentiation | Full | CSS selectors in FormatGenerator, unused | MODERATE |
| 5 | Table of contents | Multi-TOC with links | None | MAJOR |
| 6 | Chorus recall (rechorus) | Quote/tag/choruslike | Not in dispatch table | MAJOR |
| 7 | Delegate support (ABC/LilyPond) | Full with SVG output | `handle_delegate()` returns "" | MAJOR |
| 8 | Comment box styling | Framed box | Rendered but no CSS | MINOR |
| 9 | Section label display | Margin labels | data-label attr only, no CSS | MINOR |
| 10 | Grid bar lines/symbols | 7 bar types, repeats | Only chord/symbol classes | MODERATE |
| 11 | Volta brackets | Full rendering | CSS class stub only | MODERATE |
| 12 | Image alignment | center/left/right/spread | Only width/height attrs | MODERATE |
| 13 | Chord diagram positioning | top/bottom/right/below | Fixed position only | MODERATE |
| 14 | Keyboard diagrams | Full rendering | Stub: returns "(keyboard)" text | MODERATE |
| 15 | Chords-under mode | Configurable | Always chords-above | MODERATE |
| 16 | Inline chords mode | With format strings | Not supported | MODERATE |
| 17 | Annotations | Separate styling | Rendered as regular chords | MINOR |
| 18 | Chords column (side) | Dedicated column | Not supported | MODERATE |
| 19 | Strum patterns | Graphical rendering | Not supported | LOW |
| 20 | Songbook parts (cover/matter) | Cover, front, back | None | LOW |
| 21 | Song sorting | By title/artist/etc. | Input order only | LOW |
| 22 | PDF bookmarks/outlines | Full | N/A (browser domain) | N/A |
| 23 | CSV companion export | MSPro compatible | N/A (PDF-specific) | N/A |
| 24 | Font embedding | TrueType/OpenType | CSS @font-face (different model) | N/A |
| 25 | Background PDF pages | Full page underlays | N/A (different model) | N/A |

---

## Implementation Plan

<!-- ============================================================ -->

<feature>
<title>Activate Paged Mode Template Selection</title>
<implementation-decision>implement</implementation-decision>
<reason>This is the foundational blocker. The entire paged mode infrastructure (templates in html5/paged/, FormatGenerator, CSS @page rules) exists but is never activated because HTML5.pm never checks html5.mode config and never selects paged templates. Without this, features 2-4 and 5 cannot work. This is a relatively small code change with massive impact.</reason>
<priority>High</priority>
<implementation-risks>Risk: Changing template selection could break existing HTML5 output if the paged templates have rendering gaps vs the non-paged templates. Mitigation: Make paged mode opt-in only (activated by `html5.mode = "print"` config), so default behavior is unchanged. Add fallback to non-paged templates if paged template files are missing.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm`, locate the `generate_songbook()` method (around line 796). Add logic to check `$config->{html5}->{mode}` for value "print" or "paged". When detected, override the template paths to use `html5.paged.templates` from config instead of `html5.templates`. The config keys are already defined in `chordpro.json` lines 1286-1317 under `html5.paged.templates` with paths like `html5/paged/songbook.tt`, `html5/paged/song.tt`, `html5/paged/css/base.tt`.</task>
<task id=2>In `generate_default_css()` (around line 736), when paged mode is active, use the paged CSS base template (`html5/paged/css/base.tt`) which includes the `@page` rules and paged.js integration instead of the regular CSS base template.</task>
<task id=3>Update `generate_song()` (around line 446) to pass metadata as template variables when paged mode is active: `data_title`, `data_subtitle`, `data_artist`, `data_album`, `data_composer`, `data_lyricist`, `data_copyright`, `data_year`, `data_key`, `data_capo`. Extract these from `$song->{meta}` (all values are arrayrefs, join with ", " for display). The paged song.tt template already has `[% IF data_title %] data-title="[% data_title | html %]"[% END %]` conditionals that will activate once these variables are provided.</task>
<task id=4>Update the test `t/76_html5paged.t` to verify that paged mode is actually activated: check that paged.js script is included, that the paged songbook template is used, and that data-* attributes appear in song divs when metadata is present.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Headers, Footers, and Page Numbering via FormatGenerator Integration</title>
<implementation-decision>implement</implementation-decision>
<reason>FormatGenerator (`lib/ChordPro/Output/HTML5Helper/FormatGenerator.pm`) is a complete, working module that translates PDF format configs (headers/footers with %{title}, %{page}, etc.) into CSS @page margin-box rules. It handles default/title/first page formats, odd/even variants, and metadata substitutions. It is simply never instantiated or called. Wiring it in gives headers, footers, page numbers, and odd/even differentiation in one step.</reason>
<priority>High</priority>
<implementation-risks>Risk: CSS Paged Media @page margin boxes require paged.js polyfill for browser support. The polyfill is already loaded in the paged songbook template. Risk: FormatGenerator hardcodes font-size 10pt and color #666 — may not match user's theme. Mitigation: Make FormatGenerator read font config from `pdf.formats` config or add HTML5-specific format overrides. Risk: `string()` CSS function requires corresponding `string-set` rules on elements with data-* attributes — this depends on Feature 1 (metadata passthrough). Mitigation: Implement Feature 1 first.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `generate_default_css()` method (around line 736), when paged mode is active: import and instantiate `ChordPro::Output::HTML5Helper::FormatGenerator` with `$config` and `$options`. Call `$generator->generate_rules()` to get CSS @page rules. Pass the result as the `format_rules` template variable to the paged CSS base template. The template already has `[% format_rules %]` placeholder at line 10 of `html5/paged/css/base.tt`.</task>
<task id=2>Verify that the paged CSS string-set template (`html5/paged/css/string-set.tt`) correctly maps data-* attributes to CSS string-set properties. The rules should be: `.cp-song[data-title] { string-set: song-title attr(data-title); }` etc. for title, subtitle, artist, album, composer, lyricist, copyright, duration. These CSS rules allow the @page margin boxes to reference `string(song-title)` etc.</task>
<task id=3>Enhance FormatGenerator to respect theme colors: instead of hardcoded `color: #666`, read from `$config->{pdf}->{theme}->{'foreground-medium'}` with fallback to `#666`. Similarly, font-size should default to `10pt` but allow override from config.</task>
<task id=4>Add tests that generate paged HTML5 output with format config and verify that CSS @page rules appear in the output with correct margin-box content (e.g., `counter(page)`, `string(song-title)`).</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Chorus Recall (Rechorus) Support</title>
<implementation-decision>implement</implementation-decision>
<reason>The `rechorus` element type is completely missing from ChordProBase's dispatch table and HTML5 rendering. When a song uses `{chorus}` to recall a previously defined chorus, the HTML5 backend silently drops it. This is a significant functional gap — many songs rely on chorus recall. The PDF backend supports three modes: quote (re-render chorus lines), tag (show "Chorus" label), and choruslike (apply chorus styling). At minimum, quote and tag modes should be implemented.</reason>
<priority>High</priority>
<implementation-risks>Risk: The `rechorus` element has a `chorus` field containing the full chorus body when in quote mode, which needs to be re-dispatched through the rendering pipeline. This could cause issues if chorus elements contain sub-elements that are poorly handled. Mitigation: Use the existing `handle_chorus()` method for quote mode rendering, which already handles chorus body dispatch. Risk: The choruslike mode requires applying chorus CSS class to non-chorus content. Mitigation: Use an additional CSS class like `cp-choruslike` that mirrors `.cp-chorus` styling.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/ChordProBase.pm`, add `rechorus` to the dispatch table around line 127 (after the grid handler): `return $self->handle_rechorus($elt) if $type eq 'rechorus';`</task>
<task id=2>Add a `handle_rechorus()` method to ChordProBase that implements the three modes. Read the chorus recall config from `$config->{pdf}->{chorus}->{recall}` (or a future `html5.chorus.recall` config). For **quote mode** (`$recall->{quote}` is true): if `$elt->{chorus}` exists, render it using `handle_chorus()` with the chorus body. For **tag mode** (`$recall->{type}` and `$recall->{tag}`): render a comment-like element with the tag text (e.g., "Chorus"). For **default**: render a simple "Chorus" indicator div with class `cp-rechorus`.</task>
<task id=3>Add CSS for `.cp-rechorus` in the HTML5 CSS templates (sections.tt or a new rechorus section). Style it similarly to a comment with italic text indicating chorus recall. For choruslike mode, add `.cp-choruslike` class that mirrors `.cp-chorus` border/indent styling.</task>
<task id=4>Add test in `testing/` with a .cho file that uses `{chorus}` recall directive, verifying the HTML5 output contains the recalled chorus content or tag.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Delegate Support (ABC, LilyPond, Strum)</title>
<implementation-decision>implement</implementation-decision>
<reason>Delegates are a core ChordPro feature allowing embedding of ABC notation, LilyPond notation, and strum patterns. The delegate system already generates SVG output (via abc2svg, ly2svg). The legacy HTML backend supports delegates by embedding the SVG/image output directly. HTML5's `handle_delegate()` returns empty string, completely dropping all delegate content. Since delegates produce images/SVGs, the HTML5 backend can embed them directly as `<img>` or inline `<svg>` elements.</reason>
<priority>High</priority>
<implementation-risks>Risk: Delegate output may be PNG, SVG, or other formats. HTML5 needs to handle each type. Mitigation: Check `$elt->{subtype}` which indicates `image-svg`, `image-png`, etc. For SVG, inline the content; for raster images, use `<img>` with data URI or file path. Risk: abc2svg produces JavaScript-dependent SVG that may need special handling in HTML context. Mitigation: Use the same approach as the legacy HTML backend (lines 154-165 of HTML.pm) which successfully embeds delegate output. Risk: Delegates may not be installed on the user's system. Mitigation: Handle gracefully — show placeholder text if delegate processing fails (check `$elt->{data}` existence).</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm`, override `handle_delegate()` from ChordProBase. Check `$elt->{subtype}` for the delegate type. Reference `lib/ChordPro/Output/HTML.pm` lines 154-197 for the established pattern. For `image-svg` subtype: if `$elt->{data}` contains SVG data, embed it inline wrapped in `<div class="cp-delegate cp-delegate-svg">`. For `image-png` or other image subtypes: if an asset/file was generated, use `<img>` tag with the file path.</task>
<task id=2>Handle the case where delegate data is stored as an asset: check `$elt->{uri}` and `$elt->{opts}` for file paths. Use the existing `render_image()` method for file-based delegate output. Add class `cp-delegate` to distinguish from regular images.</task>
<task id=3>Add CSS for `.cp-delegate` in the HTML5 CSS templates. SVG delegates should be sized responsively (max-width: 100%, height: auto). Add margin spacing consistent with other block elements.</task>
<task id=4>Test with ABC notation input (create a .cho file with `{start_of_abc}...{end_of_abc}` block). Verify the SVG output appears in the HTML5 output. If abc2svg is not available in the test environment, test the fallback behavior (empty or placeholder).</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Comment Box Styling</title>
<implementation-decision>implement</implementation-decision>
<reason>The `{comment_box}` directive renders in HTML5 as `<div class="cp-comment_box">` via ChordProBase but has zero CSS styling — it appears as unstyled text. This is a trivial CSS addition. PDF renders it with a visible frame/border. This is a quick win.</reason>
<priority>High</priority>
<implementation-risks>Risk: Minimal. This is purely CSS. Only risk is the class name using underscore (`cp-comment_box`) which is unusual but valid CSS. Mitigation: Use the existing class name as-is; it works fine in CSS selectors.</implementation-risks>
<implementation-details>
<task id=1>In the HTML5 CSS template for typography (`lib/ChordPro/res/templates/html5/css/typography.tt`), add CSS rules for `.cp-comment_box`. Style it with: `border: 1pt solid var(--cp-color-text, #000); padding: 0.3em 0.5em; margin: 0.5em 0; display: inline-block;`. This mirrors PDF's comment_box frame rendering. Use the comment font styling (same size/color as `.cp-comment`).</task>
<task id=2>Also add `.cp-comment_box` rules to the paged CSS typography template if it exists separately, or verify the paged mode inherits from the base CSS.</task>
<task id=3>Add a simple test with a .cho file containing `{comment_box: This is boxed}` and verify the HTML5 output contains the `cp-comment_box` class with the text.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Section Label Display</title>
<implementation-decision>implement</implementation-decision>
<reason>Section labels ("Verse 1:", "Chorus:", "Bridge:") are captured in `data-label` attributes on section divs but never displayed — there are no CSS rules to render them. PDF shows them as margin text. This is a CSS-only fix using `::before` pseudo-elements. It significantly improves readability of the HTML output.</reason>
<priority>High</priority>
<implementation-risks>Risk: Labels displayed via CSS `::before` content with `attr()` are not selectable/copyable text in all browsers. Mitigation: This is acceptable for label display; alternatively, add a `<span class="cp-section-label">` element in the HTML for better accessibility. Risk: Label positioning in the margin may overlap with chorus bar styling. Mitigation: Use left margin offset that accounts for both chorus indent and label width; or display labels inline above the section rather than in margin.</implementation-risks>
<implementation-details>
<task id=1>Add CSS rules to the sections.tt template for displaying section labels. Use the `data-label` attribute: `.cp-verse[data-label]::before, .cp-chorus[data-label]::before, .cp-bridge[data-label]::before, .cp-tab[data-label]::before, .cp-grid[data-label]::before { content: attr(data-label); font-weight: bold; font-size: 0.85em; color: var(--cp-color-text, #000); display: block; margin-bottom: 0.2em; }`. This displays labels as a block element above the section content.</task>
<task id=2>Consider the PDF `labels.comment` config option which renders labels as comments instead. For HTML5, use a CSS variable `--label-display` that can be set to `none` to hide labels, defaulting to `block`.</task>
<task id=3>Verify labels render correctly in both regular and paged modes. Test with a .cho file containing `{start_of_verse: Verse 1}` and `{start_of_chorus: Chorus}` directives.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Grid Bar Lines and Repeat Symbols</title>
<implementation-decision>implement</implementation-decision>
<reason>HTML5 grid rendering handles chord tokens but renders all non-chord tokens generically via `$token->{symbol}`. It does not distinguish between bar types (|, ||, |:, :|, :|:) or repeat symbols (%, %%). The PDF backend has a sophisticated Grid.pm (374 lines) that renders each bar type with distinct visual styling. The HTML5 grid should at least render the bar symbols with proper classes for CSS styling, and handle repeat symbols.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: Grid token structure may differ between structurized and non-structurized songs. The token `{class}` field values need to be verified against actual parser output. Mitigation: Add debug logging to dump token structures from real grid .cho files. Risk: Complex bar line rendering (thick/thin combinations) requires careful CSS. Mitigation: Use Unicode box-drawing characters or CSS borders for visual distinction.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `render_gridline()` method (line 139-195), enhance the non-chord token rendering. Instead of just using `$token->{symbol}`, check for specific bar types. The token class values from the parser are: `bar` (regular |), `dbar` (double ||), `rbar` (repeat start |:), `lbar` (repeat end :|), `lrbar` (both :|:). Add specific CSS classes: `cp-grid-bar`, `cp-grid-dbar`, `cp-grid-rbar`, `cp-grid-lbar`, `cp-grid-lrbar`. For repeat symbols class `rep1` (%) and `rep2` (%%), use `cp-grid-repeat`.</task>
<task id=2>Add CSS styling for each bar type in the tab-grid.tt CSS template. Use appropriate Unicode or styled borders: regular bar = thin line, double bar = double thin, repeat bars = thick+thin with dots. Example: `.cp-grid-rbar::after { content: ":"; }` for the dots portion of repeat bars.</task>
<task id=3>Handle volta brackets: when a gridline has volta information (`$element->{volta}`), render a `<span class="cp-grid-volta" data-volta="N">` wrapper around the relevant cells. Add CSS for volta bracket display using top border + left vertical line for the bracket shape and `::before` pseudo-element for the volta number.</task>
<task id=4>Test with a .cho file containing grid sections: `{start_of_grid}\n| Am . . . | C . . . |\n|: Dm . | G . :|\n{end_of_grid}` and verify each bar type gets the correct CSS class.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Image Alignment and Sizing</title>
<implementation-decision>implement</implementation-decision>
<reason>HTML5 image rendering (`render_image()` line 333-346) only passes width/height attributes. It does not handle: alignment (center/left/right from `{image: file.png align=center}`), scale factor, or spread mode. PDF handles all these. Since images are a common ChordPro feature, alignment at minimum should be supported.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: Image options come from the `$elt->{opts}` hash which may use different key names than expected. Mitigation: Check the parser output in Song.pm for image directive parsing — the keys are `align`, `width`, `height`, `scale`, `center`. Risk: Spread images in HTML5 would need to span the full page width in paged mode, which requires different CSS for screen vs print. Mitigation: Use CSS class-based approach with media queries.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `render_image()` method (line 333-346), add handling for the `align` option from `$opts`. Map alignment values to CSS: `center` → `style="display:block; margin:0 auto;"`, `left` → `style="float:left; margin-right:1em;"`, `right` → `style="float:right; margin-left:1em;"`. Wrap image in a `<div class="cp-image-container cp-image-align-{align}">` for more flexible CSS styling.</task>
<task id=2>Add `scale` support: if `$opts->{scale}` is present, multiply width/height by the scale factor, or if dimensions are not specified, use `style="width: {scale*100}%;"` to scale relative to container.</task>
<task id=3>Add CSS for image alignment classes in the HTML5 CSS templates: `.cp-image-align-center { text-align: center; }`, `.cp-image-align-left { float: left; }`, `.cp-image-align-right { float: right; }`. Add `.cp-image-spread { width: 100%; }` for spread images.</task>
<task id=4>Also update `_render_image_template()` (line 128-137) to pass alignment and scale to the template variables, and update the image.tt template accordingly.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Chord Diagram Positioning</title>
<implementation-decision>implement</implementation-decision>
<reason>HTML5 always renders chord diagrams in a fixed position (after metadata, before body). PDF supports four positions: top (above first song line), bottom (after last song line), right (in a side column), and below (after entire song). The `diagrams.placement` config is never read by HTML5. Supporting at least top/bottom/below would improve layout flexibility with minimal effort.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: The "right" placement requires a two-column layout with the song body on the left and diagrams on the right. This is significantly more complex than top/bottom/below. Mitigation: Implement top/bottom/below first using simple div ordering; defer "right" placement to a future enhancement with CSS grid/flexbox layout. Risk: In paged mode, bottom/below placement interacts with page breaks. Mitigation: Use CSS `page-break-inside: avoid` on the diagrams container.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `generate_song()` method (around line 446-491), read the diagram placement config from `$config->{pdf}->{diagrams}->{show}` (or a future `html5.diagrams.show`). Values are: "top", "bottom", "right", "below", or false. Instead of always inserting `chord_diagrams_html` before body in the song template, pass it as a separate variable and let the template control placement.</task>
<task id=2>Update the song template (`html5/song.tt` and `html5/paged/song.tt`) to conditionally place the chord diagrams div based on a `diagrams_position` template variable. For "top": before body. For "bottom" or "below": after body. For "right": use a CSS grid layout with body and diagrams side by side.</task>
<task id=3>Add CSS for right-side diagram placement: `.cp-song-layout-right { display: grid; grid-template-columns: 1fr auto; gap: 1em; } .cp-song-layout-right .cp-chord-diagrams { grid-column: 2; grid-row: 1 / -1; }`.</task>
<task id=4>Test with config `{"pdf":{"diagrams":{"show":"bottom"}}}` and verify diagrams appear after the song body instead of before it.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Keyboard Diagram Rendering</title>
<implementation-decision>implement</implementation-decision>
<reason>The SVG chord diagram module (`ChordDiagram/SVG.pm`) has a `generate_keyboard_diagram()` stub that just returns "(keyboard)" text. The PDF backend has a full `KeyboardDiagram.pm` (301 lines) that renders piano keys with highlighted pressed notes. Keyboard instruments (piano, organ) are a supported instrument type in ChordPro. Implementing SVG keyboard diagrams would complete instrument coverage for HTML5.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: SVG keyboard diagram rendering is non-trivial — requires drawing white keys, black keys, and highlighting pressed keys. Mitigation: Follow the same approach as the PDF KeyboardDiagram.pm but generate SVG path elements instead of PDF drawing commands. The layout math (key positions, widths) is directly portable. Risk: Configuration (key count, base key C/F) needs to be read correctly. Mitigation: Read from `$config->{pdf}->{kbdiagrams}` config which has `keys`, `base`, `width`, `height`, `pressed` color settings.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/ChordDiagram/SVG.pm`, implement `generate_keyboard_diagram()` (currently a stub at line 194). Port the rendering logic from `lib/ChordPro/Output/PDF/KeyboardDiagram.pm`. Generate SVG with: a rectangle for the keyboard outline, white key rectangles, black key rectangles overlaid, and filled rectangles/circles for pressed keys. Use config values for dimensions (`kbdiagrams.width`, `kbdiagrams.height`, `kbdiagrams.keys`).</task>
<task id=2>Handle the key mapping: the chord info object provides `kbkeys` field (array of MIDI note numbers or key indices). Map these to physical key positions on the rendered keyboard. Support both C-base and F-base layouts per config `kbdiagrams.base`.</task>
<task id=3>Style the SVG output: white keys get `fill: white; stroke: black;`, black keys get `fill: black;`, pressed keys get `fill: {pressed-color}` (default blue from config). Add chord name text above the keyboard.</task>
<task id=4>Test with a .cho file that uses keyboard instrument (`{instrument: piano}`) and has chord definitions with keyboard voicings. Verify SVG keyboard diagrams appear in the HTML5 output.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Chords-Under Mode</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF supports placing chords below the lyrics line instead of above (via `settings.chords-under` config). This is a common request for certain musical styles. HTML5 always renders chords above using flexbox column direction. Since the HTML5 songline uses a flex column layout (`cp-chord-lyric-pair`), switching to chords-under is a simple CSS change (flex-direction: column-reverse).</reason>
<priority>Medium</priority>
<implementation-risks>Risk: Minimal — this is primarily a CSS change. The main risk is that the `chords-under` config key uses a dash which requires `item()` access in Template::Toolkit. Mitigation: Pass as a simple boolean template variable `chords_under` from the Perl code.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm`, in the CSS generation or song generation method, read `$config->{settings}->{'chords-under'}` and pass it as a template variable `chords_under` to the CSS template.</task>
<task id=2>In the CSS template (layout.tt or songline CSS), add a conditional: when `chords_under` is true, set `.cp-chord-lyric-pair { flex-direction: column-reverse; }`. This reverses the chord/lyric order within each pair, placing chords below lyrics.</task>
<task id=3>Also handle the case where chords-under affects spacing: when chords are under, the top padding/margin of the chord span should become bottom padding. Add appropriate CSS adjustments.</task>
<task id=4>Test with config `{"settings":{"chords-under":true}}` and verify chord elements appear after (below) lyric elements in the rendered HTML.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Inline Chords Mode</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF supports rendering chords inline within the lyrics text (e.g., "Amazing [G]grace how [C]sweet") instead of above. This is useful for compact layouts and lyric sheets. HTML5's songline rendering always uses the two-row chord-above layout. Inline mode requires a different rendering approach in `render_songline()`.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: Inline chords fundamentally change the HTML structure — instead of chord-lyric pairs in a flex container, inline chords are spans within a text flow. This requires a conditional rendering path in `render_songline()`. Mitigation: Check `$config->{settings}->{'inline-chords'}` and branch early in the songline renderer. Risk: Inline chord format strings (e.g., `[%s]`) need to be parsed. Mitigation: Use simple string substitution — replace `%s` with the chord name.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `render_songline()` method, add a check for `$config->{settings}->{'inline-chords'}` at the start. When true, use an alternative rendering path that outputs a single `<div class="cp-songline cp-inline-chords">` containing interleaved chord spans and lyric text in a single text flow: `<span class="cp-inline-chord">[Am]</span>Amazing grace`.</task>
<task id=2>Support the inline-chords format string from config (`$config->{settings}->{'inline-chords'}` can be a format string like `[%s]` or `(%s)`). Apply the format to each chord name before rendering.</task>
<task id=3>Add CSS for `.cp-inline-chord` in the typography template: `font-weight: bold; color: var(--cp-color-chord);`. The inline-chords songline should use normal text flow (no flexbox).</task>
<task id=4>Test with config `{"settings":{"inline-chords":"[%s]"}}` and a .cho file with chords, verifying that output shows chords inline within lyrics text.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Annotation Support</title>
<implementation-decision>implement</implementation-decision>
<reason>Annotations (marked with `*` prefix in chord positions, e.g., `[*N.C.]`) are treated as non-chord text annotations in ChordPro. PDF renders them with distinct styling (not as chord diagrams, different font/color). HTML5 currently renders them identically to regular chords with no visual distinction. The chord info object has an `is_annotation` method that can be checked.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: Minimal. The chord objects in the songline have an `info` method that returns chord info with `is_annotation`. Need to check if the HTML5 chord rendering path accesses chord info. Mitigation: In `render_songline()`, check if the chord object responds to `->info->is_annotation` and add an `cp-annotation` CSS class when true.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm`, in the songline chord rendering logic (where chords are converted to display text), add an annotation check: `if (ref($chord) && $chord->can('info') && $chord->info && $chord->info->is_annotation)` then add CSS class `cp-annotation` to the chord span instead of `cp-chord`.</task>
<task id=2>Add CSS for `.cp-annotation` in the typography template: `font-style: italic; color: var(--cp-color-annotation, var(--cp-color-text)); font-weight: normal;`. Annotations should look like text notes, not chord names.</task>
<task id=3>Ensure annotations are excluded from chord diagram generation — the `render_chord_diagrams()` method should skip chords where `info->is_annotation` is true. Check if this is already handled.</task>
<task id=4>Test with a .cho file containing `[*N.C.]No chord` and `[*riff]Guitar part` annotations, verifying they get the annotation class and not the chord class.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Table of Contents Generation</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF generates a full table of contents with song titles, artists, and page numbers — essential for songbook use. HTML5 has no TOC generation at all. For paged mode (print), a TOC with page numbers (via CSS `target-counter()`) is achievable with paged.js. For regular mode, a clickable TOC with anchor links is valuable for multi-song HTML files.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: CSS `target-counter(page)` for page numbers requires paged.js and may not work in all browsers/contexts. Mitigation: Make page numbers paged-mode only; in regular mode, generate a TOC with anchor links without page numbers. Risk: TOC configuration in PDF is complex (multiple TOC definitions, field grouping, letter folding). Mitigation: Implement a simple single-TOC first with title and optional artist/composer; defer advanced TOC features. Risk: TOC placement in the HTML document — it needs to come before songs. Mitigation: Generate TOC in `generate_songbook()` after processing all songs, then insert it before the songs in the template.</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `generate_songbook()` method, after collecting all song HTML, generate a TOC section. Iterate over the songs, extracting title and artist from `$song->{meta}`. Create a `<nav class="cp-toc">` with `<ol>` list items. Each item links to the song via anchor (`<a href="#song-N">`). In paged mode, add `<span class="cp-toc-page">` using CSS `target-counter(attr(href), page)` for page numbers.</task>
<task id=2>Ensure each song div has a unique ID (e.g., `id="song-1"`, `id="song-2"`) that the TOC can link to. Update the song template to include this ID on the `.cp-song` div.</task>
<task id=3>Create a TOC template (`html5/toc.tt` or inline in songbook.tt) with configurable display. Add CSS for `.cp-toc` styling: page-break-after for paged mode, clean list formatting, page number alignment.</task>
<task id=4>Read the `pdf.toc` config (or future `html5.toc`) to determine TOC fields and whether to generate a TOC at all (`toc.line` config). Default to generating TOC when there are 2+ songs.</task>
<task id=5>Test with a multi-song .cho file (or multiple input files), verifying the TOC appears with correct links and, in paged mode, page number CSS rules.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Odd/Even Page Differentiation</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF supports different headers/footers for odd (right) and even (left) pages — important for book-style double-sided printing. The FormatGenerator already handles this: it generates CSS `:left` and `:right` @page pseudo-selectors and swaps left/right content for even pages (lines 56-64, 144-156). This feature becomes available automatically once FormatGenerator is integrated (Feature 2). The only additional work is ensuring the CSS works correctly with paged.js.</reason>
<priority>Medium</priority>
<implementation-risks>Risk: CSS @page :left/:right selectors require the CSS `@page { }` writing-mode context and paged.js support. Mitigation: paged.js 0.4.3 (already loaded in paged templates) supports :left/:right pseudo-selectors. Risk: Content swapping (left footer on even pages becomes right footer) is already handled in FormatGenerator. Mitigation: Verify with test output.</implementation-risks>
<implementation-details>
<task id=1>This feature is primarily delivered by Feature 2 (FormatGenerator integration). Verify that when `pdf.formats.default-even` exists in config, FormatGenerator produces `@page :left { ... }` rules with swapped left/right content.</task>
<task id=2>Add specific test: provide config with `{"pdf":{"formats":{"default":{"footer":["","","%{page}"]},"default-even":{"footer":["%{page}","",""]}}}}` and verify the CSS output has both `@page { @bottom-right { content: counter(page); } }` and `@page :left { @bottom-left { content: counter(page); } }`.</task>
<task id=3>Test with paged.js in a browser to verify visual output shows page numbers alternating sides on odd/even pages.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Chords Column (Side Column)</title>
<implementation-decision>denied</implementation-decision>
<reason>PDF's chordscolumn feature renders all chords in a dedicated side column separate from the lyrics. This is a complex layout that requires calculating chord positions relative to lyrics, maintaining alignment, and managing a fixed-width column. In HTML/CSS, this would require a fundamentally different rendering approach (CSS grid with a fixed side column, position mapping between lyrics and chords). The complexity is high, the use case is niche, and it interacts poorly with responsive web layouts. The chords-under and inline-chords modes (Features 11-12) provide alternative compact layouts that serve similar use cases.</reason>
<priority>Low</priority>
<implementation-risks>N/A</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Strum Pattern Rendering</title>
<implementation-decision>denied</implementation-decision>
<reason>Strum patterns are rendered by the `ChordPro::Delegate::Strum` module which generates graphical strum notation. This is a delegate-based feature. Once Feature 4 (Delegate Support) is implemented, strum patterns will work automatically if they produce image/SVG output through the delegate pipeline. No separate implementation is needed — the delegate handler will embed whatever output the Strum delegate produces.</reason>
<priority>Low</priority>
<implementation-risks>N/A — covered by delegate support implementation</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Songbook Parts (Cover, Front Matter, Back Matter)</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF supports inserting cover pages (from a PDF file), front matter, and back matter into the songbook. For HTML5, cover/matter content could be HTML files or images. This is a lower-priority feature but valuable for generating complete songbook documents in HTML5 format, especially in paged/print mode.</reason>
<priority>Low</priority>
<implementation-risks>Risk: PDF cover pages use embedded PDF pages, which don't have an HTML equivalent. Mitigation: Support HTML files as cover/matter content (new config key `html5.cover`), or support images. Also could support the same PDF files by converting them to images or embedding via `<object>` tag. Risk: In paged mode, cover/matter needs correct page-break handling. Mitigation: Wrap in `<div class="cp-cover" style="page-break-after: always;">` for clean separation.</implementation-risks>
<implementation-details>
<task id=1>Add config support for `html5.cover`, `html5.front-matter`, `html5.back-matter` accepting HTML file paths or image file paths.</task>
<task id=2>In `generate_songbook()`, before the song loop, read and insert front matter content. After the song loop, insert back matter. Cover content goes before everything, wrapped in a page-break div.</task>
<task id=3>Add CSS for `.cp-cover`, `.cp-front-matter`, `.cp-back-matter` with appropriate page break rules for paged mode.</task>
<task id=4>Fallback: if config points to a PDF file (for backwards compatibility with pdf.cover), show a message or skip gracefully rather than trying to embed it.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Song Sorting</title>
<implementation-decision>implement</implementation-decision>
<reason>PDF supports sorting songs by title, subtitle, artist, etc. before rendering. HTML5 renders songs in input order. Sorting is a backend-independent operation that should happen before rendering. This is a small addition to `generate_songbook()` that improves songbook usability.</reason>
<priority>Low</priority>
<implementation-risks>Risk: Minimal — sorting is a well-understood operation. Only risk is sort key extraction from song metadata. Mitigation: Use `$song->{meta}->{title}->[0]` for title sort, etc. Handle missing metadata gracefully (sort to end).</implementation-risks>
<implementation-details>
<task id=1>In `lib/ChordPro/Output/HTML5.pm` `generate_songbook()`, before the song rendering loop, check for sort config from `$config->{pdf}->{sortby}` (or future `html5.sortby`). If present, sort the `$sb->{songs}` array by the specified field(s).</task>
<task id=2>Support the same sort syntax as PDF: array of field names with optional `+`/`-` prefix for ascending/descending. Default to case-insensitive title sort.</task>
<task id=3>Test with a multi-song input where songs are in non-alphabetical order, and config `{"pdf":{"sortby":["title"]}}`, verifying the HTML output has songs in alphabetical order.</task>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>PDF Bookmarks/Outlines</title>
<implementation-decision>denied</implementation-decision>
<reason>PDF bookmarks and outlines are a PDF-specific navigation feature (the sidebar tree in PDF viewers). HTML has no equivalent — browsers provide their own navigation mechanisms. The HTML5 TOC (Feature 13) serves the same purpose for HTML documents. Generating PDF bookmarks from HTML is meaningless.</reason>
<priority>Low</priority>
<implementation-risks>N/A</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>CSV Companion Export</title>
<implementation-decision>denied</implementation-decision>
<reason>The CSV export is a PDF-specific companion feature for MSPro compatibility — it generates a CSV file alongside the PDF for use in presentation software. This is not related to HTML5 output and serves a specific PDF workflow. HTML5 has no equivalent need.</reason>
<priority>Low</priority>
<implementation-risks>N/A</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Font Embedding (TrueType/OpenType)</title>
<implementation-decision>denied</implementation-decision>
<reason>PDF embeds fonts directly into the document. HTML uses a fundamentally different model — CSS @font-face declarations reference font files served alongside the HTML. The HTML5 backend already supports CSS font configuration through its template system. Adding PDF-style font embedding would be architecturally inappropriate; instead, users should configure CSS @font-face rules or use web fonts. The existing CSS variable system for font families is sufficient.</reason>
<priority>Low</priority>
<implementation-risks>N/A</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

<!-- ============================================================ -->

<feature>
<title>Background PDF Page Underlays</title>
<implementation-decision>denied</implementation-decision>
<reason>PDF supports overlaying song content on top of a background PDF page (for custom paper, letterheads, etc.). HTML has no mechanism to use PDF pages as backgrounds. The HTML equivalent is CSS background-image which the HTML5 backend already supports via theme colors and could be extended to support background images via CSS. However, translating PDF page underlays to HTML is not feasible and represents a fundamentally different rendering model.</reason>
<priority>Low</priority>
<implementation-risks>N/A</implementation-risks>
<implementation-details>
</implementation-details>
</feature>

---

## Implementation Order (Recommended)

### Phase 1: Foundation (High Priority)
1. **Activate Paged Mode** — everything else in print mode depends on this
2. **FormatGenerator Integration** — headers, footers, page numbers
3. **Chorus Recall** — common functional gap
4. **Comment Box Styling** — quick CSS win
5. **Section Label Display** — quick CSS win

### Phase 2: Content Parity (Medium Priority)
6. **Delegate Support (ABC/LilyPond)** — enables music notation
7. **Grid Bar Lines and Symbols** — improves grid fidelity
8. **Image Alignment** — common layout need
9. **Chords-Under Mode** — layout option
10. **Inline Chords Mode** — layout option
11. **Annotation Support** — rendering correctness
12. **Chord Diagram Positioning** — layout flexibility

### Phase 3: Songbook Features (Medium-Low Priority)
13. **Table of Contents** — songbook essential
14. **Odd/Even Pages** — print book feature (mostly free with FormatGenerator)
15. **Keyboard Diagrams** — instrument coverage

### Phase 4: Polish (Low Priority)
16. **Songbook Parts** — cover/matter pages
17. **Song Sorting** — songbook organization

### Denied (Not Applicable to HTML5)
- Chords Column (side) — too complex for HTML, alternatives exist
- Strum Patterns — covered by delegate support
- PDF Bookmarks — PDF-specific
- CSV Export — PDF workflow-specific
- Font Embedding — different model in HTML
- Background PDF Underlays — different model in HTML
