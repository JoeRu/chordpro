#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 8;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title Grids}
{start_of_grid 4x3}
| B . . | C . . | D~C . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use DDumper; warn(DDumper($s));
my $song = {
      meta => {
        songindex => 1,
        title => ['Grids'],
      },
      settings => {},
      source => { file => "__STRING__", line => 1 },
      structure => 'linear',
	    'system' => 'common',
      title => 'Grids',
      chordsinfo => { map { $_ => $_ } qw( B C D E ) },
      body => [
	       { context => 'grid',
		 name => 'gridparams',
		 type => 'set',
		 value => [4, 3, 0, 0]},
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chords => ['D','C'], class => 'chords' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       {
		'value' => '',
		'context' => 'grid',
		'name' => 'context',
		'type' => 'set'
	       },
	      ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

# Chord definitions.
$data = <<EOD;
{title Grids}
{start_of_grid 1+4x3+2}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
EOD

eval { $s->parse_file( \$data, { transpose => 2 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 2, "One more song" );
isa_ok( $s->{songs}->[1], 'ChordPro::Song', "It's a song" );

$song = {
  body => [
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
  ],
  meta => {
    songindex => 2,
    title => [
      'Grids',
    ],
  },
  settings => {},
  source => {
    file => '__STRING__',
    line => 1,
  },
  structure => 'linear',
  system => 'common',
  title => 'Grids',
  chordsinfo => { map { $_ => $_ } qw ( D E ), 'C#', 'F#' },
};

is_deeply( { %{ $s->{songs}->[1] } }, $song, "Song contents" );

$data = <<'EOD';
{title Grid Repeat Tokens}
{start_of_grid}
| % . . | %% . . |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

my $repeat_song = $s->{songs}->[2];
my ($repeat_gridline) = grep { ($_->{type} // '') eq 'gridline' } @{ $repeat_song->{body} // [] };
my %repeat_classes = map { ( $_->{class} // '' ) => 1 } @{ $repeat_gridline->{tokens} // [] };

ok( $repeat_classes{repeat1}, "Repeat token class repeat1 parsed from %" );
ok( $repeat_classes{repeat2}, "Repeat token class repeat2 parsed from %%" );
