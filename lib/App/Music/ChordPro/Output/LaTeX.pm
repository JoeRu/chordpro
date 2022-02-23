#!/usr/bin/perl

package App::Music::ChordPro::Output::LaTeX;

# relevant Latex packages - still using the template module would make it possible 
# to create any form of textual output. 
# some redesign so is required. -need to be discussed.
#
# http://songs.sourceforge.net/songsdoc/songs.html
#   https://www.ctan.org/pkg/songs
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
my $gtemplate = Template->new({
    INCLUDE_PATH => ['.',
    '/workspaces/chordpro'],
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @songs;
#    my $cfg = $::config->{html} // {};
#    foreach ( sort keys %{ $cfg->{styles} } ) {
#    }

    foreach my $song ( @{$sb->{songs}} ) {
    	push( @songs, @{ generate_song($song) } );
    }
    my $songbook = '';
    my %vars = ();
    $vars{songs} = [@songs] ;
    $gtemplate->process('songbook.tt', \%vars, $::options->{output} )
        || die $gtemplate->error();
 # i like it more to handle output through template module - but its possible to result it as array.
 #   my @generated_sb =  split(/\n/, $songbook); 
    $::options->{output} = '-';
    return [];
}

sub line_default {
    my ( $lineobject, $ref_lineobjects ) = @_;
    push(@{$gtemplatatevar{lines}}, "");
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
    foreach my $phrase (@{$lineobject->{phrases}}){
        if(defined $lineobject->{chords}){
            if (@{$lineobject->{chords}}[$index] ne '' ){
                $chord = "\\[".@{$lineobject->{chords}}[$index] ."]"; #songbook format \\[chord]
        }}
        $line .=  $chord . latex_encode($phrase);
        $index += 1; 
        $chord = "";
    }
    push(@{$gtemplatatevar{lines}}, $line);
}
$line_routines{line_songline} = \&line_songline;

sub line_newpage {
    my ( $lineobject ) = @_;
    push(@{$gtemplatatevar{lines}}, "\\newpage");
}
$line_routines{line_newpage} = \&line_newpage;

sub line_empty {
    my ( $lineobject ) = @_;
    push(@{$gtemplatatevar{lines}}, "\\brk");
}
$line_routines{line_empty} = \&line_empty;

sub line_comment {
    my ( $lineobject ) = @_; # Template for comment?

    my $vars = {
        comment => latex_encode($lineobject->{text})
    };
    my $comment = '';
    $gtemplate->process('comment.tt', $vars, \$comment) || die $gtemplate->error();
    push(@{$gtemplatatevar{lines}}, $comment);
}
$line_routines{line_comment} = \&line_comment;

sub line_comment_italic {
    my ( $lineobject ) = @_; # Template for comment?
    push(@{$gtemplatatevar{lines}}, "\\textit{".latex_encode($lineobject->{text})."}");
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
    $gtemplate->process('image.tt', $lineobject, \$image)|| die $gtemplate->error();
    push(@{$gtemplatatevar{lines}}, $image);
}
$line_routines{line_image} = \&line_image;

sub line_colb {
    my ( $lineobject ) = @_; # Template for comment?
    push(@{$gtemplatatevar{lines}}, "\\columnbreak");
}
$line_routines{line_colb} = \&line_colb;

# 'type' => 'set',
#     'context' => 'chorus',
#     'line' => 16,
#     'name' => 'label',
#     'value' => 'Refrain'
sub line_chorus {
    my ( $lineobject ) = @_; #
    push(@{$gtemplatatevar{lines}}, "\\beginchorus");
    elt_handler($lineobject->{body}); # handle lines in Context 
    # if you need to handle lines differently in context then reimplement the handler and the "line_type" subroutines accordingly
    push(@{$gtemplatatevar{lines}}, "\\endchorus");
}
$line_routines{line_chorus} = \&line_chorus;

sub line_verse {
    my ( $lineobject ) = @_; #
    push(@{$gtemplatatevar{lines}}, "\\beginverse");
    elt_handler($lineobject->{body}); # handle lines in Context
    push(@{$gtemplatatevar{lines}}, "\\endverse");
}
$line_routines{line_verse} = \&line_verse;

sub elt_handler {
    my ( $elts ) = @_; # reference to array
    my $cref; #command reference to subroutine
#    while ( @{ $elts } ) { # for each line
#    my $elt = shift(@{ $elts }); # remove from array / reference / why?
    foreach my $elt (@{ $elts }) {
    # Gang of Four-Style - sort of command pattern 
    my $sub_type = "line_".$elt->{type}; # build command "line_<linetype>"
  #  if (exists &{$sub_type}) { #check if sub is implemented / maybe hash is -would be- faster...
     if (defined $line_routines{$sub_type}) {
         $cref = $line_routines{$sub_type}; #\&$sub_type; # due to use strict - we need to get an reference to the command 
        &$cref($elt); # call line with actual line-object
    }
    else {
        line_default($elt); # default = empty line
    }
  }
}

sub generate_song {
    my ( $s ) = @_;

    my $tidy      = $::options->{tidy};
    $single_space = $::options->{'single-space'};
    $lyrics_only  = $::config->{settings}->{'lyrics-only'};
    $s->structurize; # removes empty lines 
    # open my $FH, '>', 'dump.txt';
    # print $FH Dumper $s;
    # close $FH;
    for ( $s->{title} // "Untitled" ) {
		$gtemplatatevar{title} = latex_encode($s->{title});
    }
    if ( defined $s->{subtitle} ) {
		$gtemplatatevar{subtitle} = latex_encode($s->{subtitle});
    }
    if ( defined $s->{chords}->{chords} ) {
		$gtemplatatevar{chords} = $s->{chords}->{chords};
    }
    if ( defined $s->{meta} ) {
		$gtemplatatevar{meta} = $s->{meta};
    }

    elt_handler($s->{body});
    
    my $song = '';
    my $vars =  { %gtemplatatevar };
    $gtemplate->process('song.tt', \%gtemplatatevar, \$song);
    my @s = grep { $_ ne '' } split(/\n/, $song);
    
    # open  $FH, '>', 'dump2.txt';
    # print $FH Dumper %gtemplatatevar;
    # close $FH;
    return \@s;
}

1;

# sub line_tabline {
#     my ( $lineobject ) = @_;
# }


# sub line_rechorus {
#     my ( $lineobject ) = @_;
# }

# sub line_tab {
#     my ( $lineobject ) = @_;
# }

# sub line_gridline {
#     my ( $lineobject ) = @_;
# }

# sub line_set {
#     my ( $lineobject ) = @_;
# }

# sub line_control {
#     my ( $lineobject ) = @_;
# }
