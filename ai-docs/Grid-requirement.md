## Requirements Document: Chord Grid Feature for ChordPro

### Overview

Chord grids (also called *Jazz grilles* or *harmonic grids*) display a song's chord structure
in a compact, rectangular layout. Unlike lyric lines, grids contain only chords arranged in
cells separated by bar lines. They give performers a quick visual overview of a song's harmonic
form. This document specifies requirements for a new SVG-based grid renderer with exact
positioning.

**Scope:** This document covers the grid container, grid lines, bar line symbols, cell content,
margin handling, repeat notation, and all SVG layout and rendering rules. Strum lines
(`|s` / `|S`) appear inside grids but their internal rendering (arrow symbols, strum actions)
is specified in `Strum-requirement.md`. This document describes only how strum rows integrate
spatially into the grid layout.

---

### Core Requirements

#### 1. Grid Directives

- A grid section is opened with `{start_of_grid}` (abbreviation: `{sog}`) and closed with
  `{end_of_grid}` (abbreviation: `{eog}`).
- All content lines between the two directives are interpreted as grid lines.
- Lines outside of a grid context are not interpreted as grid content.
- The grid directive may carry additional properties via keyword-value syntax:
  ```
  {start_of_grid shape="..." label="..." cc="..."}
  ```
- For legacy compatibility, the shape value may appear directly after the colon without the
  `shape=` keyword. In this legacy form no other properties can be used:
  ```
  {start_of_grid: 4x4}
  {start_of_grid: 1+4x4+1}
  ```

#### 2. Grid Shape

The shape specifies the number of cells per row and the optional left and right margin widths.

**Syntax:**

| Form | Meaning |
|------|---------|
| `cells` | Total number of chord cells per row |
| `measures x beats` | `measures` bars, each containing `beats` cells |
| `left + cells + right` | Total cells with left-margin and right-margin widths in cells |
| `left + measures x beats + right` | Combined form |

Both margins are optional. If only one margin is given, it applies to the left.

**Persistence:**

- If no shape is supplied, the shape from the preceding grid is reused.
- If the first `{start_of_grid}` in the song has no shape, the default `1+4x4+1` is used.
- Total cells per row = `measures × beats` (or the literal `cells` value).
- Left and right margin widths are in cells (they are additional positional slots, not part of
  the bar count).

**Examples:**

```
{start_of_grid shape="4x4"}          // 4 bars × 4 beats = 16 cells
{start_of_grid shape="1+4x4+1"}      // 1-cell left margin + 16 cells + 1-cell right margin
{start_of_grid shape="1+4x2+4"}      // 1-cell left margin + 8 cells + 4-cell right margin
{start_of_grid}                       // reuses previous shape
```

#### 3. Grid Label

- An optional label can be attached to a grid: `{start_of_grid label="Intro"}`.
- The label is printed in the left margin of the first row.
- Labels are also tracked for page-heading and table-of-contents purposes.
- A label may also appear as a trailing word in the legacy shape syntax:
  ```
  {start_of_grid: 4x4 Intro}
  ```

#### 4. Chord Memory

- By default, a grid section memorizes chords it encounters, making them available for chord
  diagram display elsewhere in the document.
- The chord component tag defaults to `"grid"`. It can be overridden: `cc="my-section"`.
- Setting `cc=""` disables chord memorization for that grid.
- Chords are accumulated in declaration order. Repeat markers (`%`, `%%`) cause the chords of
  the repeated measure(s) to be inserted again into the memory in their correct positions.
- Strum lines are never added to chord memory.

---

### 5. Grid Line Types

A grid section may contain two kinds of content lines:

| Line type | Prefix | Description |
|-----------|--------|-------------|
| **Grid line** | (none) | Chord cells separated by bar lines |
| **Strum line** | `\|S` or `\|s` | Strum actions aligned to the preceding chord line |

Grid line and strum line pairing rules:

- A strum line immediately following a grid line forms a *paired row*. Paired rows share
  vertically extended bar lines that span the full combined height of both rows.
- A strum line `|S` (uppercase) renders bar lines and cell separators normally.
- A strum line `|s` (lowercase) renders without visible bar lines or cell separators
  (the structural lines are suppressed).
- Multiple strum lines may not follow a single chord line (each chord line may be paired with
  at most one strum line).
- For strum rendering details (arrow symbols, rest glyphs, sub-beats) see `Strum-requirement.md`.

---

### 6. Bar Line Symbols

Bar lines appear between cells on a grid line. Valid bar line tokens:

| Symbol | Meaning |
|--------|---------|
| `\|` | Single bar line |
| `\|\|` | Double bar line |
| `\|.` | Final (end) bar line |
| `\|:` or `{` | Start-repeat bar line |
| `:\|` or `}` | End-repeat bar line |
| `:\|:` or `}{` | Combined end-repeat / start-repeat bar line |
| `\|1` | Start of volta bracket 1 (numbered ending) |
| `:\|2` | End-repeat with volta bracket 2 |
| `\|2>` | Volta bracket, aligned under the first volta of the previous row |

Rules:
- At least one bar line symbol must appear on each grid line.
- Everything before the first bar line token on a line goes into the left margin.
- Everything after the last bar line token goes into the right margin.
- A line with no bar symbol at all is placed entirely in the left margin.
- Bar lines on strum lines must correspond positionally to bar lines on the preceding chord
  line (used for bar-line height calculations).

**Unicode rendering:**

Bar line symbols may be rendered using Unicode Musical Symbol codepoints when embedded in text:

| Symbol | Unicode | Description |
|--------|---------|-------------|
| `\|` | U+1D100 | Single Barline |
| `\|\|` | U+1D101 | Double Barline |
| `\|.` | U+1D102 | Final Barline |
| `\|:` | U+1D106 | Left Repeat Sign |
| `:\|` | U+1D107 | Right Repeat Sign |
| `:\|:` | U+1D107 + U+1D106 | Combined Repeat |

When rendering bar line glyphs as text in SVG, use these Unicode characters. When drawn as
vector primitives, use the geometric specifications in section 9.

---

### 7. Cell Content Tokens

Cells in a grid line may contain the following content:

| Token | Class | Description |
|-------|-------|-------------|
| Chord name (e.g., `Am`, `G7`) | `chord` | A chord to be played |
| `chord~chord` | `chords` | Multiple chords in one cell, separated by `~` |
| `.` | `space` | Empty beat — the previous chord continues |
| `/` | `slash` | Play the current chord again (strum repeat) |
| `%` | `repeat1` | Repeat the entire previous measure |
| `%%` | `repeat2` | Repeat the last two measures |

Additional rules:

- If a chord is not known in the song's chord dictionary it is still rendered as its name string.
- Chords are subject to transposition; strum tokens and structural symbols are not.
- A `.` cell renders as empty (invisible but occupies space).
- A `/` cell renders as the "/" character.
- `%%` occupies two measures: the current and the following measure must both be blank.

**Tight-pair sub-chord positioning (multi-chord cells):**

When multiple chords appear in a single cell (`chord~chord`), and the first part is empty
(i.e., the token starts with `~`, e.g., `~Am`), the non-empty chord is drawn with a slight
rightward offset of `tight_pair_step × cell_width` (default: 0.42) to indicate the sub-beat
timing. This applies to both chord grid lines and strum lines.

---

### 8. Margin Content

- **Left margin:** Free-form text or chord notation placed before the first bar line.
  Rendered using the `grid_margin` font (defaults to the comment font).
- **Right margin / comment:** Free-form text or chord notation placed after the last bar line.
  Also rendered using the `grid_margin` font.
- Margin widths are declared by the shape's `left` and `right` values. If margin content is
  present but no margin width was declared, a warning is issued.
- Margin content may itself contain chords; these are rendered inline as chord-margin text
  (not as grid chords).

---

### 9. Repeat Notation

#### Single-measure repeat (`%`)

- Denotes that the current measure should be played the same as the immediately preceding
  measure.
- The rest of the measure must be blank (`.` tokens only).
- Rendered as a stylized "%" symbol centered in the measure.

#### Double-measure repeat (`%%`)

- Denotes that the last two measures should be played again.
- Both the current measure and the following measure must be blank.
- Rendered as two `%`-like symbols, one per measure.

**Rendering geometry (PDF-derived baseline for SVG):**

The `%` symbol is drawn as two diagonal strokes with two dots, using lines of width
`fontSize/10`, occupying roughly 0.5 × `fontSize` width. The symbol is horizontally
centered in the measure.

---

### 10. Volta Brackets

- Volta brackets mark numbered alternative endings (first ending, second ending, etc.).
- The volta number appears as a superscript label at the left edge of the bracket.
- A horizontal bracket line extends rightward from the bar line to the end of the measure
  (spanning a fraction `volta.span` of the measure width, default: 0.7).
- Volta brackets use a separate color (`volta.color`, default: `blue`).
- The `>` suffix on a volta token (e.g., `|2>`) aligns the bracket's left edge under the
  start of the first volta of the preceding row.

---

### 11. Configuration Options

All configuration resides under `pdf.grids` (with CSS custom properties for HTML5 targets).

#### `pdf.grids`

| Key | Default | Description |
|-----|---------|-------------|
| `show` | `true` | Whether to render grid sections |
| `stretch` | `0.825` | Vertical stretch factor for bar line height relative to font size |
| `symbols.color` | `blue` | Color of bar line and special symbols |
| `cellbar.width` | `0` | Width of inter-cell separator lines (0 = disabled) |
| `cellbar.color` | `foreground-medium` | Color of inter-cell separator lines |
| `volta.span` | `0.7` | Horizontal span of volta bracket as a fraction of measure width |
| `volta.color` | `blue` | Color of volta brackets and labels |

#### `pdf.spacing`

| Key | Default | Description |
|-----|---------|-------------|
| `grid` | `1.2` | Vertical spacing multiplier for grid rows |

#### `pdf.fonts`

| Key | Default | Description |
|-----|---------|-------------|
| `grid` | `Helvetica 10` | Font for chord names in grid cells |
| `grid_margin` | (comment font) | Font for margin text |
| `gridstrum` | `ChordProSymbols 13` | Font for strum symbols |

#### CSS Custom Properties (HTML5)

| Property | Description |
|----------|-------------|
| `--cp-grid-cols` | Number of columns in the token grid layout |
| `--spacing-grid` | Vertical line height multiplier |
| `--grid-symbols-color` | Color of bar/symbol glyphs |
| `--grid-volta-color` | Color of volta brackets |

---

### 12. SVG Rendering Requirements

The new implementation must render the full grid section as a single SVG image with exact,
fixed-position coordinates.

#### 12.1 Layout Model

- **Unit of measurement:** SVG user units (pixels). All positioning is absolute.
- **Cell width:** Configurable (default: 24 user units). All cells are equal width.
- **Row height:** Configurable (default: 26 user units for chord rows).
- **Row gap:** Vertical spacing between rows (default: 6 user units).
- **Total width:** `total_columns × cell_width`
- **Total height:** `num_rows × row_height + (num_rows − 1) × row_gap`

#### 12.2 Column Grid

- Every token (cell or bar) occupies exactly one column slot.
- Exception: multi-chord cells (`chords` class) occupy one slot per sub-chord part.
- Bar line positions are computed canonically from the first non-strum row and reused for all
  subsequent rows (including strum rows), so that bar lines are vertically aligned.
- Column index is 1-based. The x-coordinate of column `c` is: `x = (c − 0.5) × cell_width`.

#### 12.3 Row Positioning

- Rows are stacked top-to-bottom.
- `base_y` for row `i` (0-indexed): `base_y = i × (row_height + row_gap)`
- The text baseline for chord text is at `base_y + 16` (configurable).
- The bar line top is at `base_y + 3`.
- The bar line bottom is at `base_y + row_height − 3`.
- When a grid row is paired with a following strum row, the bar line bottom extends to:
  `base_y + 2 × row_height + row_gap − 3`.

#### 12.4 Bar Line Rendering

Bar lines are drawn as filled `<rect>` elements (or `<line>` with `stroke`) using SVG
primitives. The bar line stroke weight is `w = font_size / 10`.

| Type | Geometry |
|------|---------|
| Single `\|` | 1 vertical bar of width `w` |
| Double `\|\|` | 2 vertical bars, spaced `2w` apart |
| Final `\|.` | 1 thin + 1 thick (width `2w`) bar |
| Start repeat `\|:` | 1 thick bar + 2 dots to its right (at 0.55× and 0.15× font height) |
| End repeat `:\|` | 2 dots + 1 thick bar (mirrored) |
| Combined `:\|:` | End repeat + start repeat merged (5 elements total) |

Bar line x-position is the canonical x for the bar column, centered horizontally at `x − w/2`
for standard bars. Left-edge and right-edge bars are adjusted by `+w` for left or `−2.5w` for
right alignment.

**Strum rows:** When a strum line is `|s` (lowercase), bar `<rect>` elements are omitted from
that row. The bar lines are inherited from the paired chord row above (which already spans both
rows in height).

#### 12.5 Cell Content Rendering

Chord text is rendered as SVG `<text>` elements with `text-anchor="middle"` at the column
x-coordinate and the row text baseline y-coordinate.

```xml
<text x="12.00" y="16" text-anchor="middle" font-size="12" fill="currentColor">Am</text>
```

Rules:
- Period tokens (`.`) produce no `<text>` element.
- Slash tokens (`/`) produce a `<text>` element with content `/`.
- Multi-chord cells split the cell into equal sub-widths per part. Each part is rendered at
  its sub-column x-coordinate. Empty parts produce no element.
- When a multi-chord cell has a leading empty part (`~chord`), the non-empty chord is shifted
  right by `tight_pair_step × cell_width` (default 0.42).

#### 12.6 Repeat Symbol Rendering

The `%` (repeat one measure) preferable draws as SVG `<text>` elements with `text-anchor="middle"` and HTML-Escaped `%`;

The symbol is centered in the middle of the spanned measure. `%%` draws two such symbols,
one per measure.

#### 12.7 Volta Bracket Rendering

A volta bracket consists of:
1. A vertical bar line at the bracket's left edge (same as standard bar, using `volta.color`).
2. A horizontal line at the top of the row, extending rightward by `volta.span × measure_width`,
   with line width `w/2`.
3. A volta number label as a superscript `<text>` element at the top-left, using `volta.color`.

```xml
<text x="x+w" y="y_superscript" font-size="small" fill="blue">1.</text>
<line x1="x" y1="top" x2="x + span_width" y2="top" stroke="blue" stroke-width="..."/>
```

#### 12.8 Optional Cell Separators

When `cellbar.width > 0`, vertical separator lines are drawn between adjacent cells (not
at bar positions). These use `<rect>` elements of the configured width and color, spanning
the row height (not extended for paired strum rows).

#### 12.9 Margin Areas

- Left margin text is rendered as `<text>` left-aligned at `x = 0`, at the chord text baseline.
- Right margin text is rendered as `<text>` immediately after the last bar line position.
- Margin text uses a smaller or styled font (corresponding to `grid_margin` font settings).

#### 12.10 SVG Root Element

The SVG root element must:
- Use `xmlns="http://www.w3.org/2000/svg"`
- Set `viewBox="0 0 {width} {height}"`
- Set explicit `width` and `height` attributes (in user units)
- Use `aria-hidden="true"` (content is decorative/non-interactive)
- Set `style="font-family: {font-stack}"` for text fallback

---

### 13. Interaction with Strum Lines

When a strum line follows a chord line inside a grid block:

- The two rows form a *visual pair* sharing bar lines.
- The chord row's bar lines are extended downward to cover both rows.
- The strum row's bar lines are suppressed (for `|s`) or rendered normally (for `|S`).
- The paired rows must be rendered as a unit; they cannot be split across pages or columns.
- For strum token parsing and arrow rendering details, see `Strum-requirement.md`.

The count of strum entries on a `|s` / `|S` line must equal the number of non-bar token slots
on the preceding chord line. A mismatch is a parsing error and must be reported with a
diagnostic message.

---

### 14. Validation Rules

| Condition | Severity | Message |
|-----------|----------|---------|
| Too many non-bar tokens for declared cell count | Warning | "Too few cells for grid content" |
| Strum entry count ≠ chord slot count | Warning | "Strum line has N entries but chord line has M slots (mismatch)" |
| Margin content present without declared margin width | Warning | "No cell for margin text" / "No margin cell for trailing comment" |
| Grid shape value of zero | Error | "Invalid grid params: … (must be non-zero)" |

---

### 15. Compatibility Considerations

- The `{grid}` directive enables chord diagram display (sets `diagrams = 1`).
- The `{no_grid}` directive disables chord diagram display.
- ChordPro uses the term "chord grids" both for chord diagrams (fingering charts) and for the
  jazz-style harmonic grids described here. These are distinct features. This document covers
  only the harmonic grid (`start_of_grid` / `end_of_grid`).
- When `settings.notenames` is active and `d` is a valid note name, grid lines (class:
  `gridline`) are not confused with strum lines because strum lines are only detected when
  prefixed with `|s` or `|S`.
- Transposition applies to all chords on `gridline` rows. `strumline` rows are never transposed.
- The `grille` context (`start_of_grille`) is a legacy variant of the grid context handled
  separately; its requirements are not covered in this document.

---

### 16. Implementation Status

- PDF rendering of grids: fully functional in the reference implementation
- HTML5 rendering: partially SVG-based (strum rows use SVG; chord rows use CSS grid layout)
- New requirement: the full grid block (chord rows + strum rows) must be rendered as a single
  SVG image with exact, coordinate-based positioning
- Volta bracket HTML5 rendering: uses CSS `border-top` / `border-left` approximation
  (not SVG-precise); to be replaced by SVG path/line elements in the new renderer

---

### Design Goals

- Exact, pixel-precise placement of all grid elements (chords, bars, repeats, voltas)
- Self-contained SVG output that renders consistently across all target environments
- Prefer Unicode text glyphs for bar line characters when embedded in text elements
- Use SVG `<rect>` / `<line>` primitives for bar lines where geometric precision is required
- Maintain ChordPro's plain-text source readability (the `.cho` input format is unchanged)
- Clear separation from strum rendering: the grid renderer is responsible for layout only;
  strum arrows are delegated to the strum renderer module
- Configurable sizing (cell width, row height, font size) to allow adaptation to different
  output media without code changes
