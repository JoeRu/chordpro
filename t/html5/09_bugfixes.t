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

plan tests => 109;

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
    # Regression: split fragment with shared defs keeps referenced ids in later SVG payloads
    my $defs_split = '<div><svg xmlns="http://www.w3.org/2000/svg"><defs><g id="stdef"><path class="slW" d="M0 0h10"/></g></defs><use href="#stdef"/></svg><svg xmlns="http://www.w3.org/2000/svg"><use href="#stdef"/></svg></div>';

    my $result = $html5->_render_delegate_result({
        type    => 'image',
        subtype => 'svg',
        data    => $defs_split,
    });

    my @uris = ($result =~ /src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/g);
    is(scalar(@uris), 2, "Bug 72: Split defs payload renders two SVG image URIs");

    my $second_svg = uri_unescape($uris[1] // '');
    $second_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;
    like($second_svg, qr/<defs\b[^>]*>.*id="stdef"/s,
         "Bug 72: Referenced shared defs id is present in later split SVG");
    like($second_svg, qr/<use\b[^>]*(?:href|xlink:href)="#stdef"/,
         "Bug 72: Later split SVG keeps staff definition references");
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

        my $arrow_text_count = () = ($grid_svg =~ /<text\b[^>]*font-size="14"[^>]*>[^<]+<\/text>/g);
        cmp_ok($arrow_text_count, '>=', 6,
            "Bug 56/57: Full-grid SVG includes multiple strum arrow glyph text nodes");
        like($grid_svg, qr/<use\b[^>]*href="#bar-[^"]*"[^>]*y="3\.00"[^>]*height="[0-9.]+"/,
         "Bug 56/57: Full-grid SVG includes barline bars (icon-based)");
        like($grid_svg, qr/<svg\b[^>]*style="[^"]*font-family:[^"]*Noto Music/,
            "Bug 71: Full-grid SVG root declares Unicode-capable font stack");

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

        my @bars_paired = ($grid_svg =~ /<use\b[^>]*href="#bar-[^"]*"[^>]*y="3\.00"[^>]*height="52\.00"[^>]*\/>/g);
        my @bars_row2_split = ($grid_svg =~ /<use\b[^>]*href="#bar-[^"]*"[^>]*y="35\.00"[^>]*\/>/g);
        cmp_ok(scalar(@bars_paired), '>=', 2,
            "Bug 74: Full-grid SVG emits continuous paired-row barlines");
        is(scalar(@bars_row2_split), 0,
            "Bug 74: Full-grid SVG avoids split second-row-only barline segments");
        unlike($grid_svg, qr/stroke-width="1\.1"[^>]*stroke-linecap="round"/,
            "Bug 73: Full-grid SVG no longer emits connector line primitives");
        unlike($grid_svg, qr/<(?:line|polygon|polyline|circle)\b/,
            "Bug 76: Full-grid Strum symbol/decorator output avoids non-text SVG primitives");

        my @strum_arrow_x = ($grid_svg =~ /<text x="([0-9.]+)" y="[0-9.]+" text-anchor="middle" font-size="14" fill="currentColor">[^<]+<\/text>/g);
        cmp_ok(scalar(@strum_arrow_x), '>=', 2,
            "Bug 60: Strum row emits arrow glyph text for paired symbols");
        my $first_pair_gap = abs(($strum_arrow_x[1] // 0) - ($strum_arrow_x[0] // 0));
        cmp_ok($first_pair_gap, '<', 12,
            "Bug 60: Connected strum pairs keep visibly tight arrow spacing");
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

    my ($uri) = ($output =~ /<img(?=[^>]*class="[^"]*cp-standalone-strum-svg[^"]*")(?=[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)")[^>]*>/);
    ok($uri, "Bug 73: Standalone strum SVG data URI captured");
    my $svg = uri_unescape($uri // '');
    $svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;
    unlike($svg, qr/stroke-width="1\.1"[^>]*stroke-linecap="round"/,
        "Bug 73: Standalone strum SVG no longer emits connector line primitives");
    unlike($svg, qr/<(?:line|polygon|polyline|circle)\b/,
        "Bug 76: Standalone Strum SVG primitives are text-only");
}

{
    # Bug 61 follow-up: leading ~ tokens must not create an extra geometry shift
    my $song_data = <<'EOD';
{title: Leading Tilde Geometry}
{start_of_grid shape="0+2x4+4"}
| C ~A . . | C ~A . . |
|s dn~up dn~up ~up dn~up | dn~up dn~up ~up dn~up |
| D . . . | % . . . |
|s d+~u+ ~up d+~u+ ~up | d+~u+ ~up d+~u+ ~ux |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];
    my $output = $html5->generate_song($song);

    my ($grid_uri) = ($output =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
    ok($grid_uri, "Bug 61: Full-grid SVG captured for leading-tilde geometry check");

    my $grid_svg = uri_unescape($grid_uri // '');
    $grid_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

    my @strum_arrows = ($grid_svg =~ /<text x="([0-9.]+)" y="[0-9.]+" text-anchor="middle" font-size="14" fill="currentColor">[^<]+<\/text>/g);
    cmp_ok(scalar(@strum_arrows), '>=', 4, "Bug 61: Enough strum arrow glyphs captured for drift check");

    my $first_pair_gap = abs(($strum_arrows[1] // 0) - ($strum_arrows[0] // 0));
    my $third_pair_gap = abs(($strum_arrows[3] // 0) - ($strum_arrows[2] // 0));
    cmp_ok($third_pair_gap, '<=', $first_pair_gap + 0.01,
        "Bug 61: Leading ~up pair is not shifted wider than baseline dn~up pair");

    my ($a_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="16\.00"[^>]*>A<\/text>/);
    ok(defined $a_x, "Bug 61: Leading ~A chord label captured on first grid row");
    my $nearest_arrow_gap = 9999;
    for my $arrow_x (@strum_arrows) {
        my $gap = abs(($a_x // 0) - ($arrow_x // 0));
        $nearest_arrow_gap = $gap if $gap < $nearest_arrow_gap;
    }
    cmp_ok($nearest_arrow_gap, '<=', 0.05,
        "Bug 61: Leading ~A aligns to a strum arrow without drift");

    my @last_row_arrows = ($grid_svg =~ /<text x="([0-9.]+)" y="1(?:0[0-9]|1[0-9])\.00" text-anchor="middle" font-size="14" fill="currentColor">[^<]+<\/text>/g);
    cmp_ok(scalar(@last_row_arrows), '>=', 4,
        "Bug 61: d+~u+ rows keep visible arrow glyphs in the last strum row");

    my ($middle_bar_x) = ($grid_svg =~ /<use\b[^>]*href="#bar-single"[^>]*x="([0-9.]+)"[^>]*y="67\.00"[^>]*\/>/);
    my ($repeat_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="80\.00"[^>]*>%<\/text>/);
    ok(defined($middle_bar_x) && defined($repeat_x), "Bug 61: Repeat marker and middle barline captured");
    cmp_ok(($repeat_x // 0), '>', (($middle_bar_x // 0) + 0.5),
        "Bug 61: Repeat marker (%) stays in-cell to the right of the barline");
}

{
    # Bug 61: docs-table token normalization and semantic parity
    require ChordPro::Delegate::Strum;

    my @equiv = (
        [ 'd+', '+d' ],
        [ 'da', 'ad' ],
        [ 'dx+', '+dx' ],
        [ 'us+', 'su+' ],
    );

    for my $pair (@equiv) {
        my ($left, $right) = @$pair;
        my $lhs = ChordPro::Delegate::Strum::strum_symbol_info({ name => $left });
        my $rhs = ChordPro::Delegate::Strum::strum_symbol_info({ name => $right });
        is_deeply(
            { map { $_ => ($lhs->{$_} // 0) } qw(direction muted accent arpeggio staccato) },
            { map { $_ => ($rhs->{$_} // 0) } qw(direction muted accent arpeggio staccato) },
            "Bug 61: Equivalent token forms $left and $right normalize identically"
        );
    }

    my $ds = ChordPro::Delegate::Strum::strum_symbol_info({ name => 'ds+' });
    is($ds->{direction}, 'down', "Bug 61: ds+ maps to down direction");
    ok($ds->{staccato}, "Bug 61: ds+ sets staccato flag");
    ok($ds->{accent}, "Bug 61: ds+ sets accent flag");

    my $us = ChordPro::Delegate::Strum::strum_symbol_info({ name => 'us' });
    is($us->{direction}, 'up', "Bug 61: us maps to up direction");
    ok($us->{staccato}, "Bug 61: us sets staccato flag");
    ok(!$us->{muted}, "Bug 61: us is not treated as muted");

    my $song_data = <<'EOD';
{title: Strum Token Matrix}
{start_of_strum}
d+ +d da ad dx+ +dx ds us ds+ us+
{end_of_strum}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];
    my $output = $html5->generate_song($song);

    my ($uri) = ($output =~ /<img(?=[^>]*class="[^"]*cp-standalone-strum-svg[^"]*")(?=[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)")[^>]*>/);
    ok($uri, "Bug 61: Standalone strum SVG data URI captured for token matrix");

    my $svg = uri_unescape($uri // '');
    $svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

    my $staccato_count = () = ($svg =~ /<text\b[^>]*y="8\.00"[^>]*font-size="8"[^>]*>/g);
    cmp_ok($staccato_count, '>=', 4, "Bug 61: Staccato tokens emit dedicated text markers");

    my $accent_count = () = ($svg =~ /<text\b[^>]*y="12\.00"[^>]*font-size="9"[^>]*>/g);
    cmp_ok($accent_count, '>=', 4, "Bug 61: Accent-capable tokens emit accent text markers");

    my $muted_count = () = ($svg =~ /<text\b[^>]*y="21\.00"[^>]*font-size="9"[^>]*>/g);
    cmp_ok($muted_count, '>=', 2, "Bug 61: Muted tokens emit muted-cross text markers");
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

    # Bug 54 grids now always render as SVG (no more tokenized HTML path)
    like($output, qr/cp-grid-full-svg/, "Bug 54: Chord-only grid renders as SVG (fullsvg path)");
    my ($b54_uri) = ($output =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
    ok($b54_uri, "Bug 54: SVG data URI present for chord-only grid");
    my $b54_svg = uri_unescape($b54_uri // '');
    $b54_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;
    like($b54_svg, qr/font-size="12"[^>]*>C<\/text>/, "Bug 54: Chord C label present in SVG");
    like($b54_svg, qr/<use\b[^>]*href="#bar-repeat-start"/, "Bug 54: Repeat-start bar icon emitted in SVG");
    like($b54_svg, qr/<use\b[^>]*href="#bar-repeat-end"/, "Bug 54: Repeat-end bar icon emitted in SVG");
}

# =========================================================================
# Bug 63: Chord-strum vertical alignment — strumline column counting
# =========================================================================

{
    # Bug 63: strumline sub-beat tokens (dn~up) must occupy 1 column, not 2.
    # Each chord label's x-position must match the corresponding strum arrow.
    my $song_data = <<'EOD';
{title: Chord Strum Align}
{start_of_grid}
| C . D . |
|s dn~up . dn~up . |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];
    my $output = $html5->generate_song($song);

    my ($grid_uri) = ($output =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
    ok($grid_uri, "Bug 63: Full-grid SVG captured for chord-strum alignment check");

    my $grid_svg = uri_unescape($grid_uri // '');
    $grid_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

    # Extract chord label x-positions from row 0 (y=16.00)
    my ($c_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="16\.00"[^>]*>C<\/text>/);
    my ($d_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="16\.00"[^>]*>D<\/text>/);
    ok(defined $c_x, "Bug 63: Chord C label x-position captured");
    ok(defined $d_x, "Bug 63: Chord D label x-position captured");

    # Extract strum arrow x-positions from row 1 text-glyph symbols.
    my @strum_arrows = ($grid_svg =~ /<text x="([0-9.]+)" y="[0-9.]+" text-anchor="middle" font-size="14" fill="currentColor">[^<]+<\/text>/g);
    cmp_ok(scalar(@strum_arrows), '>=', 4,
        "Bug 63: Strum row emits glyph arrows for paired symbols");

    # Core alignment assertion: chord x matches strum arrow x
    cmp_ok(abs(($c_x // 0) - ($strum_arrows[0] // 0)), '<', 0.5,
        "Bug 63: Chord C vertically aligns with first downstroke arrow");
    cmp_ok(abs(($d_x // 0) - ($strum_arrows[2] // 0)), '<', 0.5,
        "Bug 63: Chord D vertically aligns with second downstroke arrow");

    # Verify sub-beat paired arrow is within the same column (tight_pair_step)
    my $subbeat_gap = abs(($strum_arrows[1] // 0) - ($strum_arrows[0] // 0));
    cmp_ok($subbeat_gap, '<', 12,
        "Bug 63: Sub-beat up-arrow is within column (tight pair spacing)");

    # Verify barlines align across rows
    my @bar_paired = ($grid_svg =~ /<use\b[^>]*href="#bar-[^"]*"[^>]*y="3\.00"[^>]*height="52\.00"[^>]*\/>/g);
    cmp_ok(scalar(@bar_paired), '>=', 2, "Bug 74/63: Paired rows use continuous aligned barlines");
}

{
    # Bug 63: Chord-only grid must not be affected by the strumline fix
    my $song_data = <<'EOD';
{title: Chord Only Grid}
{start_of_grid}
| C . G . | Am . F . |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];
    my $output = $html5->generate_song($song);

    # All grids now use the SVG path (plan: single canonical SVG renderer)
    like($output, qr/cp-gridline-fullsvg/,
        "Bug 63: Chord-only grid uses SVG rendering (universal SVG path)");
    like($output, qr/cp-grid-full-svg/,
        "Bug 63: Chord-only grid emits full-grid SVG img tag");
}

# =========================================================================
# Bug 64: Leading-tilde semantics (~F6 / ~up) in full-grid SVG
# =========================================================================

{
    my $song_data = <<'EOD';
{title: Leading Tilde}
{start_of_grid}
| ~F6 . G . |
|s ~up . dn . |
{end_of_grid}
EOD

    my $s = ChordPro::Songbook->new;
    $s->parse_file(\$song_data, { nosongline => 1 });
    my $song = $s->{songs}[0];
    my $output = $html5->generate_song($song);

    my ($grid_uri) = ($output =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
    ok($grid_uri, "Bug 64: Full-grid SVG captured for leading-tilde semantics");

    my $grid_svg = uri_unescape($grid_uri // '');
    $grid_svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

    my ($rest_chord_x, $f6_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="16\.00"[^>]*>[^<]+<\/text><text x="([0-9.]+)" y="16\.00"[^>]*>F6<\/text>/);
    ok(defined $rest_chord_x && defined $f6_x, "Bug 64: Chord row rest and F6 x-positions captured");
    cmp_ok(($f6_x // 0) - ($rest_chord_x // 0), '>', 6,
        "Bug 64: Leading ~F6 keeps explicit rest and shifts chord within beat");

    my ($rest_strum_x, $up_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="48\.00"[^>]*>[^<]+<\/text><line x1="([0-9.]+)" y1="52\.00" x2="\2" y2="36\.00"[^>]*\/>/);
    if (!defined $up_x) {
        ($rest_strum_x, $up_x) = ($grid_svg =~ /<text x="([0-9.]+)" y="48\.00"[^>]*>[^<]+<\/text><text x="([0-9.]+)" y="48\.00"[^>]*>[^<]+<\/text>/);
    }
    ok(defined $rest_strum_x && defined $up_x, "Bug 64: Strum row rest and upstroke x-positions captured");
    cmp_ok(($up_x // 0) - ($rest_strum_x // 0), '>', 6,
        "Bug 64: Leading ~up keeps explicit rest and shifts upstroke within beat");
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
