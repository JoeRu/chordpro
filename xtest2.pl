#!/usr/bin/perl

use Text::Markdown;
my $m = Text::Markdown->new;
my $markdown = "# headline für mich";
print $m->_RunSpanGamut($markdown);
