## Requirements Document: Strumming Patterns Feature for ChordPro

### Overview

Feature request to add strumming pattern notation to the ChordPro file format, supporting both standalone strumming pattern sections and inline strumming within chord grids.

### Core Requirements

#### 1. Strumming Pattern Scope

- Support song-level and section-level patterns (e.g., different patterns for verses vs. chorus)
- Allow multiple strumming patterns per song
- Support integration with chord grids for compact, performance-oriented display
- Chord and Strums are building "pairs"
- One Chord can have several Strums.
- Strums are combined by `~` representing a sub-beat.
- A `~` prefix or suffix signals a rhythmic rest on the adjacent sub-beat, rendered as `/` in the output:
  - `~Am` → `/Am` — rest *before* the sub-beat chord (the `~` side is the rest).
  - `Am~` → `Am/` — rest *after* the sub-beat chord.
- The `/` rest symbol may be rendered using Unicode musical rest glyphs appropriate to the beat duration:

  | Code   | Unicode | Symbol | Description                     |
  |--------|---------|--------|---------------------------------|
  | —      | 1D13A   | 𝄺      | Musical Symbol Multi Rest       |
  | —      | 1D13B   | 𝄻      | Whole Rest (semibreve rest)     |
  | —      | 1D13C   | 𝄼      | Half Rest (minim rest)          |
  | —      | 1D13D   | 𝄽      | Quarter Rest (crochet rest)     |
  | —      | 1D13E   | 𝄾      | Eighth Rest (quaver rest)       |
  | —      | 1D13F   | 𝄿      | Sixteenth Rest                  |


#### 2. Time Signature Support

- Support standard time signatures (4/4, 3/4, 6/8, 2/4) and compound meters (8/8, 16/16)
- Support triplets and quintuplets notation
- Allow odd time signatures (e.g., 7/4, as in Dave Brubeck's "Unsquare Dance")
- Support mixed time signatures within songs (e.g., "Happiness is a Warm Gun" by The Beatles)
- Provide flexible notation to avoid being restrictive
- Time signature is specified as part of the `{start_of_strum}` header (e.g., `{start_of_strum: 3/4}`)

Bars can represented by :

Code | Unicode | Symbol | Description
-----|---------|--------|--------------
`\|` | 1D100	| 𝄀 | Musical Symbol Single Barline
`\|\|` | 1D101| 𝄁  | Musical Symbol Double Barline
`\|\|:`|1D106 | 𝄆 | Musical Symbol Left Repeat Sign
`:\|\|` | 1D107 | 𝄇 | Musical Symbol Right Repeat Sign


#### 3. Tempo Specification

- Support BPM (beats per minute) for modern music
- Support text-based tempo indicators (e.g., "largo", "presto") for classical pieces
- Allow numeric values for potential audio transformation by external software


#### 4. Strumming Actions

**Basic Types:**

- Up strum (`up`)
- Down strum (`dn`)
- Rest/pause (`.`) — a deliberate rhythmic rest; no strum sounds on this beat
- Palm mute (`X`, uppercase) — non-directional mute after strum (Ultimate Guitar convention)

> **Note on `.` in chord lines vs. strum lines:** In chord grid lines, `.` means *repeat the previous chord*. In strum lines (`|s`), `.` means *no strum / rhythmic rest*. The meaning is context-dependent.

> **Case sensitivity:** `x` (lowercase) in strum modifier suffixes denotes *muted* (e.g., `dx`, `ux`). `X` (uppercase, standalone) denotes *palm mute*. These are distinct actions.

**Variations:**

- Muted/damped strum (`dx`, `ux`) - strings damped during strum
- Accented strum (`d+`, `u+`) - emphasized strum with heavier weight
- Arpeggio (`da`, `ua`) - slow strum with audible individual notes
- Staccato (`ds`, `us`) - fast strum, damped immediately after playing
**Combined Properties:**

- Support combinations like accented arpeggio (`da+`, `ua+`)
- Support accented muted strums (`dx+`, `ux+`)
- Support accented staccato (`ds+`, `us+`)
- Note: Muted and staccato are mutually exclusive (muted strums are inherently short)


The following pseudo-strums can be used:
 
| arrow           | up          |                                   | down        |                                   |
|-----------------|-------------|:---------------------------------:|-------------|:---------------------------------:|
| normal          | `up` or `u` | <span class="sym">&#x2190;</span> | `dn` or `d` | <span class="sym">&#x21a0;</span> |
| accent          | `u+`        | <span class="sym">&#x2193;</span> | `d+`        | <span class="sym">&#x21a3;</span> |
| arpeggio        | `ua`        | <span class="sym">&#x2191;</span> | `da`        | <span class="sym">&#x21a1;</span> |
| arpeggio accent | `ua+`       | <span class="sym">&#x2194;</span> | `da+`       | <span class="sym">&#x21a4;</span> |
| muted           | `ux`        | <span class="sym">&#x2196;</span> | `dx`        | <span class="sym">&#x21a6;</span> |
| muted accent    | `ux+`       | <span class="sym">&#x2199;</span> | `dx+`       | <span class="sym">&#x21a9;</span> |
| staccato        | `us`        | <span class="sym">&#x2192;</span> | `ds`        | <span class="sym">&#x21a2;</span> |
| staccato accent | `us+`       | <span class="sym">&#x2195;</span> | `ds+`       | <span class="sym">&#x21a5;</span> |

> **Symbol status:** The Unicode arrows above are *placeholders*. Final strum-specific symbols (e.g., filled/hollow directional arrows matching Ultimate Guitar conventions) will be designed in a dedicated symbol design phase.

#### 5. Notation Syntax

**Standalone Strum Sections:**

Standalone strum sections define *named, reusable patterns* that can be referenced elsewhere in the song.

```
{start_of_strum: <time-signature> <label> [tuplet]}
space-separated strum codes
{end_of_strum}
```

- `<time-signature>` — e.g., `4/4`, `3/4` (required)
- `<label>` — a name for the pattern (e.g., `verse`, `chorus-pattern`)
- `[tuplet]` — optional tuplet modifier (e.g., `triplet`, `quintuplet`)

**Referencing a named pattern:**

```
{strum: verse}
```

This inserts the strum pattern previously defined with `{start_of_strum: 4/4 verse}` at the current position, avoiding repetition.

**Grid-Embedded Strums:**

- Special grid lines prefixed with `|s` or `|S` for strum content (`|s` and `|S` are equivalent; case does not matter)
- Bar/beat markers not displayed on strum lines
- Strum lines contain *only* strum actions — they have no chords, are ignored for chord memory, and are not affected by transposition
- Support sub-beat divisions using `~` character
- **Validation:** The number of strum entries on a `|s` line *must* match the number of chord slots on the corresponding chord line above. A mismatch is a **parsing error** and must be rejected with a diagnostic message.

Example:

```
{start_of_grid: 0+4x4+2}
| C ~Am . . | C ~Am . G |
|s dn ~up dn up | dn ~up dn up |
{end_of_grid}
```

> **Grid format string:** `0+4x4+2` means `Margin + BasicBeat × Bars + Margin`, i.e., 0-cell left margin, 4 beats per bar, 4 bars, 2-cell right margin.

This would lead to the following pairs (Chord,Strum): 
Bar((C,dn), (~Am,~up), (.,dn), (.,up)),Bar(((C,dn), (~Am,~up), (.,dn), (G,up)))

Pairs are vertically aligned. The Bar-Line is covering the complete height of Chords and Strums.


#### 6. Configuration Options

- Customizable symbol display via `gridstrum.symbols` configuration
- Override default symbols with custom markup (e.g., size, color, positioning)
- Use `<sym>` notation for built-in symbols, not Unicode codepoints

Example:

```
gridstrum.symbols.dx: "<span size=90% rise=5% color='#000088'><sym arrow-down-muted/></span>"
```


#### 7. Compatibility Considerations

- Explicit strum codes (`dn`, `up`) are used. When `notenames` is set to a system where `d` is a valid note name (e.g., German or solfège notation), the parser must disambiguate strum codes from note names based on line context: `|s` lines contain *only* strum codes, never chord names.
- Transposition applies exclusively to chord grid lines. Strum lines (`|s` / `|S`) are never transposed.


### Implementation Status

- Grid-embedded strums (`|s` and `|S` lines) implemented and functional in development versions
- Comprehensive symbol set defined covering all basic and combined strum types
- Standalone `{start_of_strum}` sections with named/reusable patterns: work in progress
- PDF rendering of strum patterns: **deferred** to a later phase (HTML5 output first)
- Feature aims to balance simplicity for basic use cases with flexibility for complex patterns


### Design Goals

- Maintain ChordPro's plain-text readability
- Support both study/practice use (detailed standalone patterns) and performance use (compact grid display)
- Align with industry conventions where appropriate (e.g., Ultimate Guitar visualization)
- Provide one-character-per-strum economy for efficient notation

