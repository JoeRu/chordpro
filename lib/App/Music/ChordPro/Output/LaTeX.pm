#!/usr/bin/perl

package App::Music::ChordPro::Output::LaTeX;
# Author: Johannes Rumpf / 2022
# relevant Latex packages - still using the template module would make it possible 
# to create any form of textual output. 
# delivered example will work with songs-package - any other package needed to be 
# evaluated / tested. But should work
# http://songs.sourceforge.net/songsdoc/songs.html
# https://www.ctan.org/pkg/songs
# https://www.ctan.org/pkg/guitar
# https://www.ctan.org/pkg/songbook
# https://www.ctan.org/pkg/gchords

use strict;
use warnings;
use App::Music::ChordPro::Output::Common;
use Template;
use LaTeX::Encode;

# debug
#use Data::Dumper qw(Dumper);

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines
my %gtemplatatevar = ();
my %line_routines = ();
my $gtemplate;
my $gcfg;

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @songs;

    $gcfg = $::config->{LaTeX};

    $gtemplate = Template->new({
        INCLUDE_PATH => $gcfg->{template_include_path},
        INTERPOLATE  => 1,
    }) || die "$Template::ERROR\n";

    foreach my $song ( @{$sb->{songs}} ) {
    	push( @songs, generate_song($song) );
    }
    my $songbook = '';
    my %vars = ();
    $vars{songs} = [@songs] ;
    $gtemplate->process($gcfg->{template_songbook}, \%vars, $::options->{output} )
        || die $gtemplate->error();
 # i like it more to handle output through template module - but its possible to result it as array.
 #   return split(/\n/, $songbook); 
    $::options->{output} = '-';
    return [];
}

# some not implemented feature is requested. will be removed.
sub line_default {
    my ( $lineobject, $ref_lineobjects ) = @_;
   #return "not implemented ".$lineobject->{type}."\n";
    return "";
}
$line_routines{line_default} = \&line_default;

# 'chords' => [
#             '',
#             'D',
#             'G',
#             'D'
#             ],
# 'type' => 'songline',
# 'line' => 8,
# 'phrases' => [
#             'Swing ',
#             'low, sweet ',
#             'chari',
#             'ot,'
#             ],
# 'context' => 'chorus'
sub line_songline {
    my ( $lineobject ) = @_;
    my $index = 0;
    my $line = "";
    my $chord = "";
    my $has_chord = 0;
    foreach my $phrase (@{$lineobject->{phrases}}){
        if(defined $lineobject->{chords}){
            if (@{$lineobject->{chords}}[$index] ne '' ){
                $chord = $gcfg->{gchordstart_tag}.@{$lineobject->{chords}}[$index] .$gcfg->{gchordend_tag}; #songbook format \\[chord]
                $has_chord = 1;
        }}
        $line .=  $chord . latex_encode($phrase);
        $index += 1; 
        $chord = "";
    }
    if ($has_chord) { $line = $gcfg->{chorded_line} . $line; } else { $line = $gcfg->{unchorded_line} . $line; }
    return $line."\n";
}
$line_routines{line_songline} = \&line_songline;

sub line_newpage {
    my ( $lineobject ) = @_;
    return $gcfg->{newpage_tag} . "\n";
}
$line_routines{line_newpage} = \&line_newpage;

sub line_empty {
    my ( $lineobject ) = @_;
    return $gcfg->{emptyline_tag} . "\n";
}
$line_routines{line_empty} = \&line_empty;

sub line_comment {
    my ( $lineobject ) = @_; # Template for comment?
    my $vars = {
        comment => latex_encode($lineobject->{text})
    };
    my $comment = '';
    $gtemplate->process($gcfg->{template_comment}, $vars, \$comment) || die $gtemplate->error();
    return $comment ;
}
$line_routines{line_comment} = \&line_comment;

sub line_comment_italic {
    my ( $lineobject ) = @_; # Template for comment?
    my $vars = {
        comment => "\\textit{". latex_encode($lineobject->{text}) ."}"
    };
    my $comment = '';
    $gtemplate->process($gcfg->{template_comment}, $vars, \$comment) || die $gtemplate->error();
    return $comment;
}
$line_routines{line_comment_italic} = \&line_comment_italic;

# \begin{figure}
#   \includegraphics[width=\linewidth]{boat.jpg}
#   \caption{A boat.}
#   \label{fig:boat1}
# \end{figure}
# {
#     'opts' => {},
#     'line' => 46,
#     'context' => 'verse',
#     'uri' => 'test._22_Die_Ballade_vom_Pfeifer.png',
#     'type' => 'image'
# },
sub line_image {
    my ( $lineobject ) = @_;
    my $image = '';
    $gtemplate->process($gcfg->{template_image}, $lineobject, \$image)|| die $gtemplate->error();
    return $image;
}
$line_routines{line_image} = \&line_image;

sub line_colb {
    my ( $lineobject ) = @_; # Template for comment?
    return $gcfg->{columnbreak_tag} . "\n";
}
$line_routines{line_colb} = \&line_colb;

# 'type' => 'set',
#     'context' => 'chorus',
#     'line' => 16,
#     'name' => 'label',
#     'value' => 'Refrain'
sub line_chorus {
    my ( $lineobject ) = @_; #
   return $gcfg->{beginchorus_tag} ."\n". 
          elt_handler($lineobject->{body}) . 
          $gcfg->{endchorus_tag} . "\n";
}
$line_routines{line_chorus} = \&line_chorus;

sub line_verse {
    my ( $lineobject ) = @_; #
   return $gcfg->{beginverse_tag} ."\n". 
        elt_handler($lineobject->{body}) 
        .$gcfg->{endverse_tag} ."\n";
}
$line_routines{line_verse} = \&line_verse;

sub line_set { # potential comments in fe. Chorus or verse or .... complicated handling - potential contextsensitiv.
    my ( $lineobject ) = @_;
    return '';
}
$line_routines{line_set} = \&line_set;

sub line_tabline {
    my ( $lineobject ) = @_;
    return $lineobject->{text}."\n";
}
$line_routines{line_tabline} = \&line_tabline;

sub line_tab {
    my ( $lineobject ) = @_;
    return $gcfg->{begintab_tag}."\n". 
           elt_handler($lineobject->{body}) .
           $gcfg->{endtab_tag} ."\n";
}
$line_routines{line_tab} = \&line_tab;

sub line_grid {
    my ( $lineobject ) = @_;
    return $gcfg->{begingrid_tag}."\n".
           elt_handler($lineobject->{body}) 
           .$gcfg->{endgrid_tag} ."\n";
}
$line_routines{line_grid} = \&line_grid;

sub line_gridline {
    my ( $lineobject ) = @_;
    my $line = '';
    if(defined $lineobject->{margin}){
        $line .= $lineobject->{margin}->{text} . "\t";
    }
    else {
        $line .= "\t\t";
    }
    foreach my $token (@{ $lineobject->{tokens} }){
#        $line .= elt_handler($token);
        if ($token->{class} eq 'chord'){
            $line .= $token->{chord};
        }
        else {
           $line .= $token->{symbol};
        }
         #space, symbol, bar, repeat, repeat2
         # chord
    }
    if(defined $lineobject->{comment}){
        $line .= $lineobject->{comment}->{text};
    }
    return $line. "\n";
}
$line_routines{line_gridline} = \&line_gridline;

sub elt_handler {
    my ( $elts ) = @_; # reference to array
    my $cref; #command reference to subroutine
#    while ( @{ $elts } ) { # for each line
#    my $elt = shift(@{ $elts }); # remove from array / reference / why?
    my $lines = "";
    foreach my $elt (@{ $elts }) {
    # Gang of Four-Style - sort of command pattern 
    my $sub_type = "line_".$elt->{type}; # build command "line_<linetype>"
  #  if (exists &{$sub_type}) { #check if sub is implemented / maybe hash is -would be- faster...
     if (defined $line_routines{$sub_type}) {
        $cref = $line_routines{$sub_type}; #\&$sub_type; # due to use strict - we need to get an reference to the command 
        $lines .= &$cref($elt); # call line with actual line-object
    }
    else {
        $lines .= line_default($elt); # default = empty line
        
    }
  }
  return $lines;
}

sub my_latex_encode{
    my ( $val ) = @_;
    if ((ref($val) eq 'SCALAR') or ( ref($val) eq '' )) { return latex_encode($val); }
    if (ref($val) eq 'ARRAY'){
        my @array_return;
        foreach my $array_val (@{$val}){
            push(@array_return, my_latex_encode($array_val));
        }
        return \@array_return;
    }
    if (ref($val) eq 'HASH'){
        my %hash_return = ();
        foreach my $hash_key (keys( % {$val } )){
            $hash_return{$hash_key} = my_latex_encode( $val->{$hash_key} );
        }
        return \%hash_return;
    }
}

sub generate_song {
    my ( $s ) = @_;

    my $tidy      = $::options->{tidy};
  #  $single_spvace = $::options->{'single-space'};
  #  $lyrics_only  = $::config->{settings}->{'lyrics-only'};
    $s->structurize; # removes empty lines 
    # open my $FH, '>', 'dump.txt';
    # print $FH Dumper $s;
    # close $FH;
    %gtemplatatevar = ();
    for ( $s->{title} // "Untitled" ) {
		$gtemplatatevar{title} = latex_encode($s->{title});
    }
    if ( defined $s->{subtitle} ) {
		$gtemplatatevar{subtitle} = latex_encode($s->{subtitle});
    }

    if ( defined $s->{meta} ) {
		$gtemplatatevar{meta} = my_latex_encode($s->{meta});
    }

    if ( defined $s->{chords}->{chords} ) {
       my @chords;
        foreach my $mchord (@{$s->{chords}->{chords}}){
            # replace -1 with 'x' - alternative '-'
            my $frets = join("", map { if($_ eq '-1'){ $_ = 'X'; } +"$_"} @{$s->{chordsinfo}->{$mchord}->{frets}});
            my %chorddef = (
                "chord" => $mchord,
                "frets" => $frets,
                "base" => $s->{chordsinfo}->{$mchord}->{base},
                "fingers" => $s->{chordsinfo}->{$mchord}->{fingers});
            push(@chords, \%chorddef);
        }
        $gtemplatatevar{chords} = \@chords;
    }

    $gtemplatatevar{songlines} = elt_handler($s->{body});
    
    my $song = '';
    $gtemplate->process($gcfg->{template_song}, \%gtemplatatevar, \$song) || die $gtemplate->error();
    
    # open  $FH, '>', 'dump2.txt';
    # print $FH Dumper %gtemplatatevar;
    # close $FH;

    return $song;
}

1;


# sub line_rechorus {
#     my ( $lineobject ) = @_;
# }

# sub line_control {
#     my ( $lineobject ) = @_;
# }