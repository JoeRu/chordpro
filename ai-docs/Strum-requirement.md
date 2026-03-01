## Requirements Document: Strumming Patterns Feature for ChordPro

### Overview

Feature request to add strumming pattern notation to the ChordPro file format, supporting both standalone strumming pattern sections and inline strumming within chord grids.

### Core Requirements

#### 1. Strumming Pattern Scope

- Support song-level and section-level patterns (e.g., different patterns for verses vs. chorus)
- Allow multiple strumming patterns per song
- Support integration with chord grids for compact, performance-oriented display


#### 2. Time Signature Support

- Support standard time signatures (4/4, 8/8, 16/16)
- Support triplets and quintuplets notation
- Allow odd time signatures (e.g., 7/4, as in Dave Brubeck's "Unsquare Dance")
- Support mixed time signatures within songs (e.g., "Happiness is a Warm Gun" by The Beatles)
- Provide flexible notation to avoid being restrictive


#### 3. Tempo Specification

- Support BPM (beats per minute) for modern music
- Support text-based tempo indicators (e.g., "largo", "presto") for classical pieces
- Allow numeric values for potential audio transformation by external software


#### 4. Strumming Actions

**Basic Types:**

- Up strum (`up`)
- Down strum (`dn`)
- Rest/pause (`.` or `x`)
- None (space or `.`)

**Variations:**

- Muted/damped strum (`dx`, `ux`) - strings damped during strum
- Accented strum (`d+`, `u+`) - emphasized strum with heavier weight
- Arpeggio (`da`, `ua`) - slow strum with audible individual notes
- Staccato (`ds`, `us`) - fast strum, damped immediately after playing
- Palm mute (`X`) - non-directional mute after strum (following Ultimate Guitar convention)

**Combined Properties:**

- Support combinations like accented arpeggio (`da+`, `ua+`)
- Support accented muted strums (`dx+`, `ux+`)
- Support accented staccato (`ds+`, `us+`)
- Note: Muted and staccato are mutually exclusive (muted strums are inherently short)


#### 5. Notation Syntax

**Standalone Strum Sections:**

```
{start_of_strum [label] [tuplet]}
space-separated strum codes
{end_of_strum}
```

**Grid-Embedded Strums:**

- Special grid lines prefixed with `|s` or `|S` for strum content
- Bar/beat markers not displayed on strum lines
- Strum lines treated as non-chord content (ignored for chord memory and transposition)
- Support sub-beat divisions using `~` character

Example:

```
{start_of_grid: 0+4x4+2}
| C ~Am . . | C ~Am . G |
|s dn ~up dn up | dn ~up dn up |
{end_of_grid}
```


#### 6. Configuration Options

- Customizable symbol display via `gridstrum.symbols` configuration
- Override default symbols with custom markup (e.g., size, color, positioning)
- Use `<sym>` notation for built-in symbols, not Unicode codepoints

Example:

```
gridstrum.symbols.dx: "<span size=90% rise=5% color='#000088'><sym arrow-down-muted/></span>"
```


#### 7. Compatibility Considerations

- explicit codes (`dn`, `up`) with automatic handling based on `notenames` setting
- Ensure proper transposition handling for chords in strum grid lines


### Implementation Status

- Grid-embedded strums (`|s` and `|S` lines) implemented and functional in development versions
- Comprehensive symbol set defined covering all basic and combined strum types
- Standalone `{start_of_strum}` sections remain work in progress
- Feature aims to balance simplicity for basic use cases with flexibility for complex patterns


### Design Goals

- Maintain ChordPro's plain-text readability
- Support both study/practice use (detailed standalone patterns) and performance use (compact grid display)
- Align with industry conventions where appropriate (e.g., Ultimate Guitar visualization)
- Provide one-character-per-strum economy for efficient notation

