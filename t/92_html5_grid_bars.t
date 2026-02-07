#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $input = 'html5_grid_bars.cho';
my $out = 'out/html5_grid_bars.html';

@ARGV = (
    '--no-default-configs',
    '--generate', 'HTML5',
    '--output', $out,
    $input,
);
::run();

ok(-f $out, 'HTML5 output generated');

open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like($content, qr/cp-grid-bar-repeat-start/, 'Repeat start bar class present');
like($content, qr/cp-grid-bar-repeat-end/, 'Repeat end bar class present');
like($content, qr/cp-grid-bar-repeat-both/, 'Repeat both bar class present');
like($content, qr/cp-grid-bar-double/, 'Double bar class present');
like($content, qr/cp-grid-bar-end/, 'End bar class present');

unlink $out;
