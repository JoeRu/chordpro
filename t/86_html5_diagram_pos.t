#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 8;

make_path('out');

my $input = 'html5_diagram_pos.cho';

sub run_position_test {
    my ($label, $config_json, $assert_cb) = @_;

    my $out = "out/html5_diagram_pos_${label}.html";
    my $cfg = "out/html5_diagram_pos_${label}.json";

    open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
    print {$cfg_fh} $config_json;
    close $cfg_fh;

    @ARGV = (
        '--no-default-configs',
        '--generate', 'HTML5',
        '--config', $cfg,
        '--output', $out,
        $input,
    );
    ::run();

    ok(-f $out, "HTML5 output generated for $label placement");

    open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
    my $content = do { local $/; <$out_fh> };
    close $out_fh;

    $assert_cb->($content);

    like(
        $content,
        qr/\.cp-diagram-svg\s*\{[^}]*max-width:\s*var\(--cp-diagram-width\)/s,
        'Diagram SVG sizing is constrained via CSS'
    );

    unlink $out;
    unlink $cfg;
}

run_position_test(
    'bottom',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"bottom","align":"right"}}}',
    sub {
        my ($content) = @_;
        my ($song_html) = $content =~ /<div class="cp-song[^"]*">([\s\S]*?)<\/div><!-- \.cp-song -->/;
        my $line_pos = index($song_html // '', 'Line one');
        my $diagram_pos = index($song_html // '', '<div class="cp-chord-diagrams');
        ok($diagram_pos > $line_pos, 'Bottom placement renders diagrams after body');
        like($content, qr/cp-chord-diagrams-align-right/, 'Bottom placement applies alignment class');
    },
);

run_position_test(
    'right',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"right","align":"center"}}}',
    sub {
        my ($content) = @_;
        like($content, qr/cp-song-layout-right/, 'Right placement applies layout class');
        like($content, qr/class="cp-song-body"/, 'Right placement wraps body content');
    },
);
