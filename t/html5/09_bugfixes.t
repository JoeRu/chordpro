#!/usr/bin/perl

# Comprehensive tests for HTML5 backend bug fixes
# Bug 1: Chord alignment - lyrics misaligned when no chord at line start
# Bug 2: Images not showing - URI not resolved from assets
# Bug 3: Empty SRC tags - same root cause as Bug 2
# Bug 4: Delegated SVG/ABC not shown - delegate result image URI handling
# Bug 5: Special chars (&#39;) shown literally - double-escaping in templates

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use File::Temp qw(tempdir);
use MIME::Base64 qw(encode_base64);

plan tests => 30;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend instance
my $html5 = ChordPro::Output::HTML5->new(
    config  => $config,
    options => { output => undef },
);
ok($html5, "HTML5 backend created");

# =========================================================================
# Bug 1: Chord alignment - .cp-chord-empty must use visibility:hidden
# =========================================================================

diag("--- Bug 1: Chord alignment (visibility:hidden) ---");

{
    my $css = $html5->generate_default_css();
    ok($css, "CSS generated");

    # The fix: visibility:hidden preserves space for proper alignment
    like($css, qr/\.cp-chord-empty\s*\{[^}]*visibility:\s*hidden/s,
         "Bug 1: .cp-chord-empty uses visibility:hidden");

    # Ensure display:none is NOT used (that caused the alignment bug)
    unlike($css, qr/\.cp-chord-empty\s*\{[^}]*display:\s*none/s,
           "Bug 1: .cp-chord-empty does NOT use display:none");
}

# Test with a song that has lines without leading chords
{
    my $song_data = <<'EOD';
{title: Alignment Test}

{start_of_verse}
No chord here at the start
[C]This line has a chord
Middle [G]of this line [Am]has chords
{end_of_verse}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    ok($output, "Bug 1: Song with mixed chord/no-chord lines rendered");

    # Lines without leading chords should have cp-chord-empty spans
    # (due to the template rendering pairs with empty chords)
    like($output, qr/No chord here/, "Bug 1: Lyrics without chords present");
    like($output, qr/cp-songline/, "Bug 1: Songline structure present");
}

# =========================================================================
# Bug 2+3: Images not showing / Empty SRC tags - URI resolution from assets
# =========================================================================

diag("--- Bug 2+3: Image URI resolution ---");

{
    # Create a temporary image file for testing
    my $tmpdir = tempdir(CLEANUP => 1);
    my $img_path = "$tmpdir/test.png";

    # Write a minimal valid 1x1 PNG
    my $png_data = pack("H*",
        "89504e470d0a1a0a0000000d49484452" .
        "00000001000000010802000000907753" .
        "de0000000c4944415408d763f8cf0000" .
        "000200016540cd730000000049454e44" .
        "ae426082"
    );
    open my $fh, '>:raw', $img_path or die "Cannot write test image: $!";
    print $fh $png_data;
    close $fh;

    # Simulate a song with an image element stored in assets
    my $song_data = <<EOD;
{title: Image Test}

{image: $img_path}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    ok($output, "Bug 2: Song with image rendered");

    # The image should be embedded as base64 data URI (not empty src)
    like($output, qr/src="data:image\/png;base64,/,
         "Bug 2: Image embedded as base64 data URI");

    # SRC should NOT be empty
    unlike($output, qr/src=""\s/,
           "Bug 3: Image src is NOT empty");
}

# =========================================================================
# Bug 4: Delegated SVG/ABC objects
# =========================================================================

diag("--- Bug 4: Delegate element handling ---");

{
    # Test the _render_delegate_result method with SVG data
    my $svg_data = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle cx="50" cy="50" r="40"/></svg>';

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => $svg_data,
    });

    ok($result, "Bug 4: SVG delegate result rendered");
    like($result, qr/cp-delegate.*cp-delegate-svg/,
         "Bug 4: SVG wrapped in delegate container");
    like($result, qr/<svg.*<\/svg>/s,
         "Bug 4: SVG content preserved");
}

{
    # Test delegate result with array data (some delegates return arrays)
    my @svg_lines = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">',
        '<circle cx="50" cy="50" r="40"/>',
        '</svg>',
    );

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => \@svg_lines,
    });

    ok($result, "Bug 4: SVG delegate with array data rendered");
    like($result, qr/<circle/,
         "Bug 4: Array SVG content preserved");
}

{
    # Test delegate result with bitmap data (base64 encoding)
    my $png_data = pack("H*",
        "89504e470d0a1a0a0000000d49484452" .
        "00000001000000010802000000907753" .
        "de0000000c4944415408d763f8cf0000" .
        "000200016540cd730000000049454e44" .
        "ae426082"
    );

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'png',
        data    => $png_data,
    });

    ok($result, "Bug 4: PNG delegate result rendered");
    like($result, qr/src="data:image\/png;base64,/,
         "Bug 4: PNG data embedded as base64");
}

# =========================================================================
# Bug 5: Special chars double-escaping (&#39; shown literally)
# =========================================================================

diag("--- Bug 5: Special characters / double-escaping ---");

{
    # Test with single quotes in title, artist, lyrics
    my $song_data = <<'EOD';
{title: It's A Beautiful Day}
{artist: O'Brien & Friends}
{subtitle: Rock'n'Roll}

{start_of_verse}
[C]It's a [G]wonderful life
Don't [Am]stop believin'
{end_of_verse}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    ok($output, "Bug 5: Song with special chars rendered");

    # Title should NOT have double-escaped entities
    # Wrong: &amp;#39; (double-escaped) or &#39; (unnecessarily escaped in display)
    unlike($output, qr/&amp;#39;/,
           "Bug 5: No double-escaped &#39; in output");
    unlike($output, qr/&amp;amp;/,
           "Bug 5: No double-escaped &amp; in output");

    # The title in the h1 should be properly escaped (& → &amp;) but NOT double-escaped
    # O'Brien & Friends should appear with & properly handled
    like($output, qr/<h1 class="cp-title">[^<]*It&#39;s/,
         "Bug 5: Title apostrophe properly escaped once");

    # Verify lyrics content doesn't double-escape
    like($output, qr/It&#39;s a/,
         "Bug 5: Lyrics apostrophe properly escaped once");
}

{
    # Test with ampersand in metadata
    my $song_data = <<'EOD';
{title: Tom & Jerry}
{artist: Hanna & Barbera}

{start_of_verse}
[C]Hello
{end_of_verse}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    ok($output, "Bug 5: Song with ampersand rendered");

    # Should have &amp; (single escape) not &amp;amp; (double escape)
    unlike($output, qr/&amp;amp;/,
           "Bug 5: Ampersand not double-escaped");

    # Title should contain properly escaped content
    like($output, qr/<h1[^>]*>Tom &amp; Jerry<\/h1>/,
         "Bug 5: Title ampersand properly single-escaped");
}

diag("All bug fix tests completed");
