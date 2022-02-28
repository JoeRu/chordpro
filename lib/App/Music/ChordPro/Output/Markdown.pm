#!/usr/bin/perl
package main;

our $options;
our $config;

package App::Music::ChordPro::Output::Markdown;
# Author: Johannes Rumpf / 2022

use strict;
use warnings;
use App::Music::ChordPro::Output::Common;
use Text::Layout::Markdown;

# debug
#use Data::Dumper qw(Dumper);

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines
my $chords_under = 0;		# chords under lyrics
# my $layout = Text::Layout::Markdown->new; # markup render in songline isnt working
my $text_layout = Text::Layout::Text->new; 
my %line_routines = ();
my $tidy;
my $rechorus;
my $act_song;


sub upd_config {
    $lyrics_only  = $config->{settings}->{'lyrics-only'};
    $chords_under = $config->{settings}->{'chords-under'};
    $rechorus  = $config->{text}->{chorus}->{recall};
}

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;
   # push(@book, "[TOC]"); # maybe https://metacpan.org/release/IMAGO/Markdown-TOC-0.01 to create a TOC?

    foreach my $song ( @{$sb->{songs}} ) {
		$act_song = $song;
		if ( @book ) {
			push(@book, "") if $options->{'backend-option'}->{tidy};
		}
		push(@book, @{generate_song($song)});
		push(@book, "---\n"); #Horizontal line between each song
	}

    push( @book, "");
    \@book;
}

# some not implemented feature is requested. will be removed.
sub line_default {
    my ( $lineobject, $ref_lineobjects ) = @_;
   #return "not implemented ".$lineobject->{type}."\n";
    return "";
}
$line_routines{line_default} = \&line_default;

sub chord {
    my ( $c ) = @_;
    return "" unless length($c);
    my $ci = $act_song->{chordsinfo}->{$c};
    return "<<$c>>" unless defined $ci;
    $text_layout->set_markup($ci->show);
    my $t = $text_layout->render;
    return $ci->is_annotation ? "*$t" : $t;
}

sub md_textline{
	my ( $songline ) = @_;
	my $empty = $songline;
    my $textline = $songline;
    my $nbsp = "\x{00A0}"; #unicode for nbsp sign
    if($empty =~ /^\s+/){ # starts with spaces
	    $empty =~ s/^(\s+).*$/$1/; # not the elegant solution - but working - replace all spaces in the beginning of a line
        my $replaces = $empty;  #with a nbsp symbol as the intend tend to be intentional
        $replaces =~ s/\s/$nbsp/g;
        $textline =~ s/$empty/$replaces/;
    }
	$textline = $textline."  "; # append two spaces to force linebreak in Markdown
	return $textline;
}

sub line_songline {
    my ( $elt ) = @_;
    my $t_line = "";
    my @phrases = map { $text_layout->set_markup($_); $text_layout->render }
      @{ $elt->{phrases} };

    if ( $lyrics_only or
	   $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$t_line = join( "", @phrases );
	return md_textline($t_line);
    }

    unless ( $elt->{chords} ) { # i guess we have a line with no chords now... 
	   return ( md_textline(join( " ", @phrases )) );
    }

    if ( my $f = $::config->{settings}->{'inline-chords'} ) {
	$f = '[%s]' unless $f =~ /^[^%]*\%s[^%]*$/;
	$f .= '%s';
	foreach ( 0..$#{$elt->{chords}} ) {
	    $t_line .= sprintf( $f,
				chord( $elt->{chords}->[$_] ),
				$phrases[$_] );
	}
	return ( md_textline($t_line) );
    }

	my $c_line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$c_line .= chord( $song, $elt->{chords}->[$_] ) . " ";
	$t_line .= $phrases[$_];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0;
	$c_line .= " " x -$d if $d < 0;
    } # this looks like setting the chords above the words.

    s/\s+$// for ( $t_line, $c_line );

	# main problem in markdown - a fixed position is only available in "Code escapes" so weather to set
	# a tab or a double backticks (``)  - i tend to the tab - so all lines with tabs are "together"
	if ($c_line ne ""){ # Block-lines are not replacing initial spaces - as the are "code"
		$t_line = "\t".$t_line."  ";
		$c_line = "\t".$c_line."  ";
		}
	else{
		$t_line = md_textline($t_line);
	}
	return $chords_under
		? ( $t_line, $c_line )
		: ( $c_line, $t_line )
}
$line_routines{line_songline} = \&line_songline;

sub line_newpage {
    return "---";
}
$line_routines{line_newpage} = \&line_newpage;

sub line_empty {
    return "";
}
$line_routines{line_empty} = \&line_empty;

sub line_comment {
    my ( $elt ) = @_; # Template for comment?
	my @s;
	push(@s, "") if $tidy;
	my $text = $elt->{text};
	if ( $elt->{chords} ) {
		$text = "";
		for ( 0..$#{ $elt->{chords} } ) {
		    $text .= "[" . $elt->{chords}->[$_] . "]"
		      if $elt->{chords}->[$_] ne "";
		    $text .= $elt->{phrases}->[$_];
	}}

	if ($elt->{type} =~ /italic$/) {
			$text = "*" . $text . "*  ";
		}
	push(@s, "> $text  ");
	push(@s, "") if $tidy;
	
    return @s;
}
$line_routines{line_comment} = \&line_comment;

sub line_comment_italic {
    my ( $lineobject ) = @_; # Template for comment?
    return "> *". $lineobject->{text} ."*";;
}
$line_routines{line_comment_italic} = \&line_comment_italic;


sub line_image {
    my ( $elt ) = @_;
	return "![](".$elt->{uri}.")";
}
$line_routines{line_image} = \&line_image;

sub line_colb {
    return "\n\n\n";
}
$line_routines{line_colb} = \&line_colb;


sub line_chorus {
    my ( $lineobject ) = @_; #
	my @s;
	push(@s, "") if $tidy;
    push(@s, "**chorus**");
	push(@s, elt_handler($lineobject->{body}));
	push(@s, "\x{00A0}  ");
   return @s;
}
$line_routines{line_chorus} = \&line_chorus;

sub line_verse {
	my ( $lineobject ) = @_; #
	my @s;

	push(@s, "") if $tidy;
	push(@s, "**Verse**  ");
	push(@s, elt_handler($lineobject->{body}));
	push(@s, "") if $tidy;
    push(@s, "\x{00A0}  ");
	return @s;
}
$line_routines{line_verse} = \&line_verse;

sub line_set { # potential comments in fe. Chorus or verse or .... complicated handling - potential contextsensitiv.
    my ( $elt ) = @_;
		
	if ( $elt->{name} eq "lyrics-only" ) {
	$lyrics_only = $elt->{value}
		unless $lyrics_only > 1;
	}
	# Arbitrary config values.
	elsif ( $elt->{name} =~ /^(text\..+)/ ) {
	my @k = split( /[.]/, $1 );
	my $cc = {};
	my $c = \$cc;
	foreach ( @k ) {
		$c = \($$c->{$_});
	}
	$$c = $elt->{value};
	$config->augment($cc);
	upd_config();
	}
	
    return '';
}
$line_routines{line_set} = \&line_set;

sub line_tabline {
    my ( $lineobject ) = @_;
	return  "\t".$lineobject->{text};
}
$line_routines{line_tabline} = \&line_tabline;

sub line_tab {
    my ( $lineobject ) = @_;
	my @s;
	push(@s, "") if $tidy;
	push(@s, "**Tabulatur**  "); #@todo
	
	push(@s, map { "\t".$_ } elt_handler($lineobject->{body}) ); #maybe this need to go for code markup as well´?
	push(@s, "") if $tidy;
    return @s;
}
$line_routines{line_tab} = \&line_tab;

sub line_grid { #@todo
    my ( $lineobject ) = @_;
	my @s;
	push(@s, "") if $tidy;
	push(@s, "**Grid**  ");
	push(@s, elt_handler($lineobject->{body}));
	push(@s, "") if $tidy;
    push(@s, "\x{00A0}  ");

    return @s;
}
$line_routines{line_grid} = \&line_grid;

sub line_gridline {
    my ( $elt ) = @_;
	my @a = @{ $elt->{tokens} };
	@a = map { $_->{class} eq 'chord'
			 ? $_->{chord}
			 : $_->{symbol} } @a;
    return "\t".join("", @a);
}
$line_routines{line_gridline} = \&line_gridline;

sub elt_handler {
    my ( $elts ) = @_; # reference to array
    my $cref; #command reference to subroutine
#    while ( @{ $elts } ) { # for each line
#    my $elt = shift(@{ $elts }); # remove from array / reference / why?
    my @lines;
    foreach my $elt (@{ $elts }) {
    # Gang of Four-Style - sort of command pattern 
    my $sub_type = "line_".$elt->{type}; # build command "line_<linetype>"
  #  if (exists &{$sub_type}) { #check if sub is implemented / maybe hash is -would be- faster...
     if (defined $line_routines{$sub_type}) {
        $cref = $line_routines{$sub_type}; #\&$sub_type; # due to use strict - we need to get an reference to the command 
        push(@lines, &$cref($elt)); # call line with actual line-object
    }
    else {
        push(@lines, line_default($elt)); # default = empty line
        
    }
  }
  return @lines;
}

sub generate_song {
    my ( $s ) = @_;
    $tidy      = $options->{'backend-option'}->{tidy};
    $single_space = $options->{'single-space'};
    upd_config();
    
    # $single_spvace = $::options->{'single-space'};
    $s->structurize
      if ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';

    my @s;

    push(@s, "# " . $s->{title}) if defined $s->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"## $_" } @{$s->{subtitle}});
    }

    push(@s, "") if $tidy;
	if ( $lyrics_only eq 0 ){
		my $all_chords = "";
		# https://chordgenerator.net/D.png?p=xx0212&s=2 # reuse of other projects (https://github.com/einaregilsson/ChordImageGenerator)?
		# generate png-out of this project? // fingers also possible - but not set in basics.
		foreach my $mchord (@{$s->{chords}->{chords}}){
			# replace -1 with 'x' - alternative '-'
			my $frets = join("", map { if($_ eq '-1'){ $_ = 'x'; } +"$_"} @{$s->{chordsinfo}->{$mchord}->{frets}});
			$all_chords .= "![$mchord](https://chordgenerator.net/$mchord.png?p=$frets&s=2) ";
			
		}
		push(@s, $all_chords);
  	}  

	push(@s, elt_handler($s->{body}));
   
    return \@s;
}


package Text::Layout::Text;

use parent 'Text::Layout';

# Eliminate warning when HTML backend is loaded together with Text backend.
no warnings 'redefine';

sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self;
}

sub render {
    my ( $self ) = @_;
    my $res = "";
    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	$res .= $fragment->{text};
    }
    $res;
}


1;


# sub line_rechorus {
#     my ( $lineobject ) = @_;
	    # if ( $rechorus->{quote} ) {
		# unshift( @elts, @{ $elt->{chorus} } );
	    # }
	    # elsif ( $rechorus->{type} &&  $rechorus->{tag} ) {
		# push( @s, "{".$rechorus->{type}.": ".$rechorus->{tag}."}" );
	    # }
	    # else {
		# push( @s, "{chorus}" );
	    # }	 
# }

# sub line_control {
#     my ( $lineobject ) = @_;
# }
