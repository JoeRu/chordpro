#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

plan tests => 3;

my $input = "html5_delegate_svg.cho";
my $out = "out/html5_delegate_svg.html";

@ARGV = (
    "--generate", "HTML5",
    "--output", $out,
    $input,
);
::run();

ok( -f $out, "Generated delegate HTML5 output" );

open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like( $content, qr/cp-delegate/, "Delegate container present" );
like( $content, qr/<svg\b[^>]*>/, "SVG delegate output embedded" );

unlink $out;
