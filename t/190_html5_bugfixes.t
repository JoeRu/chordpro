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
use URI::Escape qw(uri_unescape);

plan tests => 64;

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

    # Lines without leading chords should have proper lyrics
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
        like($result, qr/<img\b[^>]*cp-delegate[^>]*cp-delegate-svg[^>]*>/,
            "Bug 4: SVG rendered as delegate image");
            like($result, qr/src="data:image\/svg\+xml;charset=utf-8,(?![^"]*%3Cdiv%3E)/i,
                "Bug 4: SVG data embedded as URL-encoded image URI without wrapped div payload");
        unlike($result, qr/<svg.*<\/svg>/s,
            "Bug 4: Inline SVG markup is not emitted");
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
            like($result, qr/src="data:image\/svg\+xml;charset=utf-8,(?![^"]*%3Cdiv%3E)/i,
                "Bug 4: Array SVG content embedded as URL-encoded image URI");
        unlike($result, qr/<circle/,
            "Bug 4: Inline SVG element content is not emitted");
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

{
    # Regression: Unicode text in SVG should not trigger wide-character fatal errors
    my $svg_data = '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="30"><text x="2" y="20">heart’s</text></svg>';

    my $result = eval {
        $html5->_render_delegate_result({
            type    => 'image',
            subtype => 'svg',
            data    => $svg_data,
        });
    };

    is($@, '', "Bug 4: Unicode SVG delegate data does not throw wide-character fatal");
        like($result // '', qr/src="data:image\/svg\+xml;charset=utf-8,(?![^"]*%3Cdiv%3E)/i,
            "Bug 4: Unicode SVG payload encoded as URL-encoded image data URI");
}

{
    # Regression: HTML5 should always pass pagewidth to ABC and Lilypond delegates
    require ChordPro::Delegate::ABC;
    require ChordPro::Delegate::Lilypond;

    my @calls;
    {
        no warnings 'once';
        no warnings 'redefine';

        local *ChordPro::Delegate::ABC::abc2svg_html = sub {
            my ( $song, %args ) = @_;
            push @calls, { delegate => 'ABC', pagewidth => $args{pagewidth} };
            return { type => 'html', data => '' };
        };

        local *ChordPro::Delegate::Lilypond::ly2svg = sub {
            my ( $song, %args ) = @_;
            push @calls, { delegate => 'Lilypond', pagewidth => $args{pagewidth} };
            return { type => 'html', data => '' };
        };

        $html5->_render_delegate_element({
            type     => 'image',
            subtype  => 'delegate',
            delegate => 'ABC',
            handler  => 'abc2svg_html',
            data     => [ 'X:1', 'K:C', 'C' ],
        });

        $html5->_render_delegate_element({
            type     => 'image',
            subtype  => 'delegate',
            delegate => 'Lilypond',
            handler  => 'ly2svg',
            opts     => { width => 512 },
            data     => [ q{\relative { c'4 }} ],
        });
    }

    is( scalar(@calls), 2, "Bug 4/48: Both delegate handlers were called" );
    is( $calls[0]->{pagewidth}, 680, "Bug 4/48: ABC delegate receives default pagewidth" );
    is( $calls[1]->{pagewidth}, 512, "Bug 4/48: Lilypond delegate receives explicit width" );
}

{
    # Regression: Multi-SVG delegate payload should render one image per <svg>
    my $multi_svg = '<div><svg xmlns="http://www.w3.org/2000/svg" id="abc-1" width="100" height="20"></svg><svg xmlns="http://www.w3.org/2000/svg" id="abc-2" width="100" height="20"></svg></div>';

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => $multi_svg,
    });

    my $img_count = () = ($result =~ /<img\b/g);
    my $uri_count = () = ($result =~ /data:image\/svg\+xml;charset=utf-8,/g);

    is($img_count, 2, "Bug 4/49: Multi-SVG payload renders two IMG elements");
    is($uri_count, 2, "Bug 4/49: Multi-SVG payload produces two SVG data URIs");
}

{
    # Regression: split SVG payload should carry shared style to later fragments
    my $multi_svg_with_style = '<div><svg xmlns="http://www.w3.org/2000/svg" width="100" height="20"><style>.abc{font-family:SharedFont}</style><text class="abc">A</text></svg><svg xmlns="http://www.w3.org/2000/svg" width="100" height="20"><text class="abc">B</text></svg></div>';

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => $multi_svg_with_style,
    });

    my $style_count = () = ($result =~ /SharedFont/g);
    is($style_count, 2, "Bug 4/50: Shared SVG style is present in all split SVG image payloads");
    unlike($result, qr/<svg\b[^>]*><text class="abc">B<\/text><\/svg>/,
           "Bug 4/50: Second split SVG is not emitted without injected style");
}

{
    # Regression: split fragment with partial local style still inherits shared style
    my $partial_style_split = '<div><svg xmlns="http://www.w3.org/2000/svg"><style>.slW{stroke:#000}.sW{stroke:#111}</style><path class="slW" d="m0 0h1"/></svg><svg xmlns="http://www.w3.org/2000/svg"><style>.f3{font:italic 10px text,serif}</style><path class="slW" d="m0 0h1"/></svg></div>';

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => $partial_style_split,
    });

    my $shared_class_count = () = ($result =~ /\.slW%7B/g);
    ok($shared_class_count >= 2, "Bug 4/51: Shared style classes are present in both split SVG payloads");
    like($result, qr/\.f3%7Bfont%3Aitalic%2010px%20text%2Cserif%7D/, "Bug 4/51: Local style in later fragment is preserved");
}

{
    # Regression: chord diagrams should be emitted as <img> data URIs, not inline <svg>
    my $song_data = <<'EOD';
{title: Diagram Encapsulation}
{define: C base-fret 1 frets x 3 2 0 1 0 fingers 0 3 2 0 1 0}
[C]Line with chord
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
        like($output, qr/<img\b[^>]*class="cp-diagram-svg"/,
            "Bug 4/43: Chord diagram image class emitted");
        like($output, qr/src="data:image\/svg\+xml;charset=utf-8,/,
            "Bug 4/43: Chord diagram rendered via SVG data URI");
    unlike($output, qr/<svg\b[^>]*class="cp-diagram-svg"/,
           "Bug 4/43: Inline diagram SVG is not emitted");
}

{
    # Regression: strum gridline should render with strum glyphs in HTML5
    my $song_data = <<'EOD';
{title: Strum Grid}
{start_of_grid shape="0+4x8+0"}
|: C . . . || G . . . :| C . . . |. G . . . |
|S dn~up dn~~up ~ ~up | dn~up ~ dn~up ~up | dn~~up ~ dn~up ~ | dn~up ~ dn~~up ~ |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    like($output, qr/class="cp-gridline\s+cp-gridline-fullsvg"/,
         "Bug 57: Grid with strum rows is rendered as unified full-grid SVG block");
    unlike($output, qr/\bcp-grid-token\b/,
           "Bug 57: Unified grid output avoids tokenized grid span pipeline");

    my ($grid_uri) = ($output =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
    ok($grid_uri, "Bug 57: Full-grid SVG data URI captured");
    my $grid_svg = uri_unescape($grid_uri // '');
        $grid_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

        my $arrow_count = () = ($grid_svg =~ /<polygon\b[^>]*fill="currentColor"/g);
        cmp_ok($arrow_count, '>=', 6,
            "Bug 56/57: Full-grid SVG includes multiple strum arrow heads");
        like($grid_svg, qr/<line\b[^>]*y1="3\.00"[^>]*stroke-width="1"/,
         "Bug 56/57: Full-grid SVG includes barline strokes");

        like($grid_svg, qr/text-anchor="middle"[^>]*font-size="6"/,
            "Bug 56/57: Full-grid SVG contains bar marker text nodes");
        like($grid_svg, qr/font-size="12"[^>]*>C<\/text>/,
            "Bug 56/57: Full-grid SVG contains chord label text");
        like($grid_svg, qr/font-size="12"[^>]*>G<\/text>/,
            "Bug 56/57: Full-grid SVG contains second chord label text");
        like($grid_svg, qr/viewBox="0 0 [0-9.]+ [0-9.]+"/,
            "Bug 56/57: Full-grid SVG carries explicit viewBox geometry");
        unlike($grid_svg, qr/Appearance=ARRAY\(/,
            "Bug 59: Full-grid SVG does not leak Perl object stringification labels");

        my @bars_row1 = ($grid_svg =~ /<line x1="([0-9.]+)" y1="3\.00" x2="\1" y2="23\.00" stroke="currentColor" stroke-width="1"\/>/g);
        my @bars_row2 = ($grid_svg =~ /<line x1="([0-9.]+)" y1="35\.00" x2="\1" y2="55\.00" stroke="currentColor" stroke-width="1"\/>/g);
        cmp_ok(scalar(@bars_row1), '>=', 2,
            "Bug 60: Full-grid SVG top row includes barline anchors");
        cmp_ok(scalar(@bars_row2), '>=', 2,
            "Bug 60: Full-grid SVG strum row includes barline anchors");
        is($bars_row1[0], $bars_row2[0],
            "Bug 60: First barline anchor is aligned across chord and strum rows");

        my @strum_stems = ($grid_svg =~ /<line x1="([0-9.]+)" y1="(?:36\.00|52\.00)" x2="\1" y2="(?:52\.00|36\.00)" stroke="currentColor" stroke-width="1\.6"\/>/g);
        cmp_ok(scalar(@strum_stems), '>=', 2,
            "Bug 60: Strum row emits arrow stems for paired symbols");
        my $first_pair_gap = abs(($strum_stems[1] // 0) - ($strum_stems[0] // 0));
        cmp_ok($first_pair_gap, '<', 16,
            "Bug 60: Connected strum pairs render with tight arrow spacing");
}

{
    # Feature 58: standalone strum sections should parse/render for HTML5
    my $song_data = <<'EOD';
{title: Standalone Strum Section}
{start_of_strum: label="Verse Groove"}
dn up dn~up | dn~up
{end_of_strum}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);
    like($output, qr/cp-delegate-strum-block/, "Feature 58: Standalone strum section renders HTML block");
    like($output, qr/cp-standalone-strum-svg/, "Feature 58: Standalone strum section renders as SVG image");
}

{
    # Regression: complex repeat tokens expose deterministic anchor/cell metadata
    my $song_data = <<'EOD';
{title: Grid Repeat Anchors}
{start_of_grid}
|: C . . | G . . :|
| % . . | %% . . |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];

    my $output = $html5->generate_song($song);

    like($output, qr/cp-grid-token-bar/, "Bug 54: Bar tokens emit explicit bar-role class");
    like($output, qr/cp-grid-repeat-anchor/, "Bug 54: Repeat tokens emit anchor class");
    like($output, qr/<span(?=[^>]*data-token-class="repeat1")(?=[^>]*data-anchor-start="\d+")(?=[^>]*data-anchor-end="\d+")[^>]*>/,
         "Bug 54: Repeat1 token includes anchor start/end metadata");
        like($output, qr/<span(?=[^>]*data-token-class="repeat1")(?=[^>]*style="[^"]*grid-column-start:[^"]*")[^>]*>/,
            "Bug 54: Repeat1 token emits explicit grid-column span style");
    like($output, qr/data-cell-index="\d+"/, "Bug 54: Grid cell index metadata emitted for cell tokens");
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
    # Wrong: &amp;#39; (double-escaped)
    unlike($output, qr/&amp;#39;/,
           "Bug 5: No double-escaped &#39; in output");
    unlike($output, qr/&amp;amp;/,
           "Bug 5: No double-escaped &amp; in output");

    # The title should be properly escaped (single-pass)
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
