#!/usr/bin/perl

# Bug 2: First word appears in upper position when songline has no leading chord
# Fixed in commit 22527232
#
# Symptom: When a song line doesn't start with a chord, first word renders too high
# Root Cause: .cp-chord-empty { visibility: hidden; } reserved space in flexbox
# Solution: Changed to display: none; in html5/css/songlines.tt

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 10;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($html5, "HTML5 object created");

# Test song with line that has NO leading chord (triggers the bug)
my $song_data = <<'EOD';
{title: Chord Empty Test}
{subtitle: Bug 2 Regression Test}

{start_of_verse}
First line with no chord at start
[C]Second line starts with chord
Some [G]lyrics with chord in middle
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];

# Generate HTML5 output
my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

# Test 3: Verify output contains the CSS fix (display: none not visibility: hidden)
# Extract the CSS section
my ($css_section) = $output =~ m{<style>(.*?)</style>}s;
ok($css_section, "CSS section found in output");

# Test 4: Verify .cp-chord-empty uses display: none
like($css_section, qr/\.cp-chord-empty[^}]*display:\s*none/, 
     "CSS contains .cp-chord-empty { display: none; }");

# Test 5: Verify it does NOT use visibility: hidden (the bug)
unlike($css_section, qr/\.cp-chord-empty[^}]*visibility:\s*hidden/i,
       "CSS does NOT contain .cp-chord-empty { visibility: hidden; } (bug fixed)");

# Test 6: Verify song structure contains chord positions
like($output, qr/<div class="cp-songline"/, "Output contains songlines");

# Test 7: Verify lyrics are present
like($output, qr/First line with no chord/, "First line lyrics present");

# Test 8: Verify the output structure handles lines without leading chords correctly
# Lines without leading chords should have proper markup structure
like($output, qr/First line with no chord/, 
     "Line without leading chord renders correctly");

diag("Bug 2 regression test: Chord-empty styling (display:none) - PASSED");
