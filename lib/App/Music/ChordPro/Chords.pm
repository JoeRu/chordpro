#! perl

package App::Music::ChordPro::Chords;

use strict;
use warnings;

use constant CHORD_BUILTIN =>  0;
use constant CHORD_USER    =>  1;
use constant CHORD_EASY    =>  0;
use constant CHORD_HARD    =>  1;
use constant N             => -1;

my $chords =
{
 "Ab"	       => [  1, 3, 3, 2, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Ab+"	       => [  N, N, 2, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ab4"	       => [  N, N, 1, 1, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ab7"	       => [  N, N, 1, 1, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ab11"	       => [  1, 3, 1, 3, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Absus"       => [  N, N, 1, 1, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Absus4"      => [  N, N, 1, 1, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Abdim"       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Abmaj"       => [  1, 3, 3, 2, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Abmaj7"      => [  N, N, 1, 1, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Abm"	       => [  1, 3, 3, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Abmin"       => [  1, 3, 3, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Abm7"	       => [  N, N, 1, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],

 "A"	       => [  N, 0, 2, 2, 2, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "A+"	       => [  N, 0, 3, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A4"	       => [  0, 0, 2, 2, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A6"	       => [  N, N, 2, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A7"	       => [  N, 0, 2, 0, 2, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "A7+"	       => [  N, N, 3, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A7(9+)"      => [  N, 2, 2, 2, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A9"	       => [  N, 0, 2, 1, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A11"	       => [  N, 4, 2, 4, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A13"	       => [  N, 0, 1, 2, 3, 1,	 5, CHORD_BUILTIN, CHORD_HARD ],
 "A7sus4"      => [  0, 0, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A9sus"       => [  N, 0, 2, 1, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Asus"	       => [  N, N, 2, 2, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Asus2"       => [  0, 0, 2, 2, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Asus4"       => [  N, N, 2, 2, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Adim"	       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Amaj"	       => [  N, 0, 2, 2, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Amaj7"       => [  N, 0, 2, 1, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am"	       => [  N, 0, 2, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Amin"	       => [  N, 0, 2, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "A/D"	       => [  N, N, 0, 0, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A/F#"	       => [  2, 0, 2, 2, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A/G#"	       => [  4, 0, 2, 2, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Am#7"	       => [  N, N, 2, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am(7#)"      => [  N, 0, 2, 2, 1, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am6"	       => [  N, 0, 2, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am7"	       => [  N, 0, 2, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Am7sus4"     => [  0, 0, 0, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am9"	       => [  N, 0, 1, 1, 1, 3,	 5, CHORD_BUILTIN, CHORD_HARD ],
 "Am/G"	       => [  3, 0, 2, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Amadd9"      => [  0, 2, 2, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Am(add9)"    => [  0, 2, 2, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "A#"	       => [  N, 1, 3, 3, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#+"	       => [  N, N, 0, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#4"	       => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#7"	       => [  N, N, 1, 1, 1, 2,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "A#sus"       => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#sus4"      => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#maj"       => [  N, 1, 3, 3, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#maj7"      => [  N, 1, 3, 2, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#dim"       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#m"	       => [  N, 1, 3, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#min"       => [  N, 1, 3, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "A#m7"	       => [  N, 1, 3, 1, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Bb"	       => [  N, 1, 3, 3, 3, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Bb+"	       => [  N, N, 0, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bb4"	       => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bb6"	       => [  N, N, 3, 3, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bb7"	       => [  N, N, 1, 1, 1, 2,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "Bb9"	       => [  1, 3, 1, 2, 1, 3,	 6, CHORD_BUILTIN, CHORD_HARD ],
 "Bb11"	       => [  1, 3, 1, 3, 4, 1,	 6, CHORD_BUILTIN, CHORD_HARD ],
 "Bbsus"       => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbsus4"      => [  N, N, 3, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbmaj"       => [  N, 1, 3, 3, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbmaj7"      => [  N, 1, 3, 2, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbdim"       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbm"	       => [  N, 1, 3, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Bbmin"       => [  N, 1, 3, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Bbm7"	       => [  N, 1, 3, 1, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bbm9"	       => [  N, N, N, 1, 1, 3,	 6, CHORD_BUILTIN, CHORD_HARD ],

 "B"	       => [  N, 2, 4, 4, 4, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "B+"	       => [  N, N, 1, 0, 0, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B4"	       => [  N, N, 3, 3, 4, 1,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "B7"	       => [  0, 2, 1, 2, 0, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "B7+"	       => [  N, 2, 1, 2, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B7+5"	       => [  N, 2, 1, 2, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B7#9"	       => [  N, 2, 1, 2, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B7(#9)"      => [  N, 2, 1, 2, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B9"	       => [  1, 3, 1, 2, 1, 3,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "B11"	       => [  1, 3, 3, 2, 0, 0,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "B11/13"      => [  N, 1, 1, 1, 1, 3,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "B13"	       => [  N, 2, 1, 2, 0, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bsus"	       => [  N, N, 3, 3, 4, 1,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "Bsus4"       => [  N, N, 3, 3, 4, 1,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "Bmaj"	       => [  N, 2, 4, 3, 4, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bmaj7"       => [  N, 2, 4, 3, 4, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bdim"	       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bm"	       => [  N, 2, 4, 4, 3, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Bmin"	       => [  N, 2, 4, 4, 3, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "B/F#"	       => [  0, 2, 2, 2, 0, 0,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "BaddE"       => [  N, 2, 4, 4, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "B(addE)"     => [  N, 2, 4, 4, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "BaddE/F#"    => [  2, N, 4, 4, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Bm6"	       => [  N, N, 4, 4, 3, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bm7"	       => [  N, 1, 3, 1, 2, 1,	 2, CHORD_BUILTIN, CHORD_EASY ],
 "Bmmaj7"      => [  N, 1, 4, 4, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bm(maj7)"    => [  N, 1, 4, 4, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bmsus9"      => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bm(sus9)"    => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Bm7b5"       => [  1, 2, 4, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "C"	       => [  N, 3, 2, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "C+"	       => [  N, N, 2, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C4"	       => [  N, N, 3, 0, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C6"	       => [  N, 0, 2, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C7"	       => [  0, 3, 2, 3, 1, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "C9"	       => [  1, 3, 1, 2, 1, 3,	 8, CHORD_BUILTIN, CHORD_HARD ],
 "C9(11)"      => [  N, 3, 3, 3, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C11"	       => [  N, 1, 3, 1, 4, 1,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "Csus"	       => [  N, N, 3, 0, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Csus2"       => [  N, 3, 0, 0, 1, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Csus4"       => [  N, N, 3, 0, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Csus9"       => [  N, N, 4, 1, 2, 4,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "Cmaj"	       => [  0, 3, 2, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Cmaj7"       => [  N, 3, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Cm"	       => [  N, 1, 3, 3, 2, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Cmin"	       => [  N, 1, 3, 3, 2, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Cdim"	       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C/B"	       => [  N, 2, 2, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Cadd2/B"     => [  N, 2, 0, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "CaddD"       => [  N, 3, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C(addD)"     => [  N, 3, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Cadd9"       => [  N, 3, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C(add9)"     => [  N, 3, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "C3"	       => [  N, 1, 3, 3, 2, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Cm7"	       => [  N, 1, 3, 1, 2, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Cm11"	       => [  N, 1, 3, 1, 4, N,	 3, CHORD_BUILTIN, CHORD_HARD ],

 "C#"	       => [  N, N, 3, 1, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#+"	       => [  N, N, 3, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#4"	       => [  N, N, 3, 3, 4, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "C#7"	       => [  N, N, 3, 4, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#7(b5)"     => [  N, 2, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#sus"       => [  N, N, 3, 3, 4, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "C#sus4"      => [  N, N, 3, 3, 4, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "C#maj"       => [  N, 4, 3, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#maj7"      => [  N, 4, 3, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#dim"       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#m"	       => [  N, N, 2, 1, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#min"       => [  N, N, 2, 1, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "C#add9"      => [  N, 1, 3, 3, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "C#(add9)"    => [  N, 1, 3, 3, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "C#m7"	       => [  N, N, 2, 4, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Db"	       => [  N, N, 3, 1, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Db+"	       => [  N, N, 3, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Db7"	       => [  N, N, 3, 4, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbsus"       => [  N, N, 3, 3, 4, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Dbsus4"      => [  N, N, 3, 3, 4, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "Dbmaj"       => [  N, N, 3, 1, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbmaj7"      => [  N, 4, 3, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbdim"       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbm"	       => [  N, N, 2, 1, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbmin"       => [  N, N, 2, 1, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dbm7"	       => [  N, N, 2, 4, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "D"	       => [  N, N, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "D+"	       => [  N, N, 0, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D4"	       => [  N, N, 0, 2, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D6"	       => [  N, 0, 0, 2, 0, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D7"	       => [  N, N, 0, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "D7#9"	       => [  N, 2, 1, 2, 3, 3,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "D7(#9)"      => [  N, 2, 1, 2, 3, 3,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "D9"	       => [  1, 3, 1, 2, 1, 3,	10, CHORD_BUILTIN, CHORD_HARD ],
 "D11"	       => [  3, 0, 0, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dsus"	       => [  N, N, 0, 2, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dsus2"       => [  0, 0, 0, 2, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dsus4"       => [  N, N, 0, 2, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D7sus2"      => [  N, 0, 0, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D7sus4"      => [  N, 0, 0, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dmaj"	       => [  N, N, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dmaj7"       => [  N, N, 0, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ddim"	       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm"	       => [  N, N, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Dmin"	       => [  N, N, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "D/A"	       => [  N, 0, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D/B"	       => [  N, 2, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D/C"	       => [  N, 3, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D/C#"	       => [  N, 4, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D/E"	       => [  N, 1, 1, 1, 1, N,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "D/G"	       => [  3, N, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D5/E"	       => [  0, 1, 1, 1, N, N,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "Dadd9"       => [  0, 0, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D(add9)"     => [  0, 0, 0, 2, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D9add6"      => [  1, 3, 3, 2, 0, 0,	10, CHORD_BUILTIN, CHORD_HARD ],
 "D9(add6)"    => [  1, 3, 3, 2, 0, 0,	10, CHORD_BUILTIN, CHORD_HARD ],

 "Dm6(5b)"     => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm7"	       => [  N, N, 0, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Dm#5"	       => [  N, N, 0, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm(#5)"      => [  N, N, 0, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm#7"	       => [  N, N, 0, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm(#7)"      => [  N, N, 0, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm/A"	       => [  N, 0, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm/B"	       => [  N, 2, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm/C"	       => [  N, 3, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm/C#"       => [  N, 4, 0, 2, 3, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Dm9"	       => [  N, N, 3, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "D#"	       => [  N, N, 3, 1, 2, 1,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "D#+"	       => [  N, N, 1, 0, 0, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#4"	       => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#7"	       => [  N, N, 1, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#sus"       => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#sus4"      => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#maj"       => [  N, N, 3, 1, 2, 1,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "D#maj7"      => [  N, N, 1, 3, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#dim"       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#m"	       => [  N, N, 4, 3, 4, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#min"       => [  N, N, 4, 3, 4, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "D#m7"	       => [  N, N, 1, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Eb"	       => [  N, N, 3, 1, 2, 1,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "Eb+"	       => [  N, N, 1, 0, 0, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Eb4"	       => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Eb7"	       => [  N, N, 1, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebsus"       => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebsus4"      => [  N, N, 1, 3, 4, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebmaj"       => [  N, N, 1, 3, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebmaj7"      => [  N, N, 1, 3, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebdim"       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebadd9"      => [  N, 1, 1, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Eb(add9)"    => [  N, 1, 1, 3, 4, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebm"	       => [  N, N, 4, 3, 4, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebmin"       => [  N, N, 4, 3, 4, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Ebm7"	       => [  N, N, 1, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "E"	       => [  0, 2, 2, 1, 0, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "E+"	       => [  N, N, 2, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E5"	       => [  0, 1, 3, 3, N, N,	 7, CHORD_BUILTIN, CHORD_HARD ],
 "E6"	       => [  N, N, 3, 3, 3, 3,	 9, CHORD_BUILTIN, CHORD_HARD ],
 "E7"	       => [  0, 2, 2, 1, 3, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "E7#9"	       => [  0, 2, 2, 1, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E7(#9)"      => [  0, 2, 2, 1, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E7(5b)"      => [  N, 1, 0, 1, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E7b9"	       => [  0, 2, 0, 1, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E7(b9)"      => [  0, 2, 0, 1, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E7(11)"      => [  0, 2, 2, 2, 3, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E9"	       => [  1, 3, 1, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "E11"	       => [  1, 1, 1, 1, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Esus"	       => [  0, 2, 2, 2, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Esus4"       => [  0, 2, 2, 2, 0, 0,	 0, CHORD_BUILTIN, CHORD_HARD ],
 "Emaj"	       => [  0, 2, 2, 1, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Emaj7"       => [  0, 2, 1, 1, 0, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Edim"	       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em"	       => [  0, 2, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Emin"	       => [  0, 2, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Em6"	       => [  0, 2, 2, 0, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em7"	       => [  0, 2, 2, 0, 3, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Em/B"	       => [  N, 2, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em/D"	       => [  N, N, 0, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em7/D"       => [  N, N, 0, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Emsus4"      => [  0, 0, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em(sus4)"    => [  0, 0, 2, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Emadd9"      => [  0, 2, 4, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Em(add9)"    => [  0, 2, 4, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "F"	       => [  1, 3, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F+"	       => [  N, N, 3, 2, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F+7+11"      => [  1, 3, 3, 2, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F4"	       => [  N, N, 3, 3, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F6"	       => [  N, 3, 3, 2, 3, N,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F7"	       => [  1, 3, 1, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F9"	       => [  2, 4, 2, 3, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F11"	       => [  1, 3, 1, 3, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fsus"	       => [  N, N, 3, 3, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fsus4"       => [  N, N, 3, 3, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fmaj"	       => [  1, 3, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fmaj7"       => [  N, 3, 3, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fdim"	       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fm"	       => [  1, 3, 3, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Fmin"	       => [  1, 3, 3, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F/A"	       => [  N, 0, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F/C"	       => [  N, N, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F/D"	       => [  N, N, 0, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F/G"	       => [  3, 3, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F7/A"	       => [  N, 0, 3, 0, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fmaj7/A"     => [  N, 0, 3, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fmaj7/C"     => [  N, 3, 3, 2, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fmaj7(+5)"   => [  N, N, 3, 2, 2, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fadd9"       => [  3, 0, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F(add9)"     => [  3, 0, 3, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "FaddG"       => [  1, N, 3, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "FaddG"       => [  1, N, 3, 2, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Fm6"	       => [  N, N, 0, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Fm7"	       => [  1, 3, 1, 1, 1, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Fmmaj7"      => [  N, 3, 3, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "F#"	       => [  2, 4, 4, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F#+"	       => [  N, N, 4, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#7"	       => [  N, N, 4, 3, 2, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F#9"	       => [  N, 1, 2, 1, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#11"	       => [  2, 4, 2, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#sus"       => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#sus4"      => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#maj"       => [  2, 4, 4, 3, 2, 2,	 0, CHORD_BUILTIN, CHORD_HARD ],
 "F#maj7"      => [  N, N, 4, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#dim"       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#m"	       => [  2, 4, 4, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F#min"       => [  2, 4, 4, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F#/E"	       => [  0, 4, 4, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#4"	       => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#m6"	       => [  N, N, 1, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "F#m7"	       => [  N, N, 2, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "F#m7-5"      => [  1, 0, 2, 3, 3, 3,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "F#m/C#m"     => [  N, N, 4, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Gb"	       => [  2, 4, 4, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Gb+"	       => [  N, N, 4, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gb7"	       => [  N, N, 4, 3, 2, 0,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "Gb9"	       => [  N, 1, 2, 1, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbsus"       => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbsus4"      => [  N, N, 4, 4, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbmaj"       => [  2, 4, 4, 3, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbmaj7"      => [  N, N, 4, 3, 2, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbdim"       => [  N, N, 1, 2, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbm"	       => [  2, 4, 4, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbmin"       => [  2, 4, 4, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gbm7"	       => [  N, N, 2, 2, 2, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "G"	       => [  3, 2, 0, 0, 0, 3,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "G+"	       => [  N, N, 1, 0, 0, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G4"	       => [  N, N, 0, 0, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G6"	       => [  3, N, 0, 0, 0, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7"	       => [  3, 2, 0, 0, 0, 1,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "G7+"	       => [  N, N, 4, 3, 3, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7b9"	       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7(b9)"      => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7#9"	       => [  1, 3, N, 2, 4, 4,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "G7(#9)"      => [  1, 3, N, 2, 4, 4,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "G9"	       => [  3, N, 0, 2, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G9(11)"      => [  1, 3, 1, 3, 1, 3,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "G11"	       => [  3, N, 0, 2, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gsus"	       => [  N, N, 0, 0, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gsus4"       => [  N, N, 0, 0, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G6sus4"      => [  0, 2, 0, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G6(sus4)"    => [  0, 2, 0, 0, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7sus4"      => [  3, 3, 0, 0, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G7(sus4)"    => [  3, 3, 0, 0, 1, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gmaj"	       => [  3, 2, 0, 0, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gmaj7"       => [  N, N, 4, 3, 2, 1,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "Gmaj7sus4"   => [ N, N, 0, 0, 1, 2,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gmaj9"       => [  1, 1, 4, 1, 2, 1,	 2, CHORD_BUILTIN, CHORD_HARD ],
 "Gm"	       => [  1, 3, 3, 1, 1, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Gmin"	       => [  1, 3, 3, 1, 1, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Gdim"	       => [  N, N, 2, 3, 2, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gadd9"       => [  1, 3, N, 2, 1, 3,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "G(add9)"     => [  1, 3, N, 2, 1, 3,	 3, CHORD_BUILTIN, CHORD_HARD ],
 "G/A"	       => [  N, 0, 0, 0, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G/B"	       => [  N, 2, 0, 0, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G/D"	       => [  N, 2, 2, 1, 0, 0,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "G/F#"	       => [  2, 2, 0, 0, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],

 "Gm6"	       => [  N, N, 2, 3, 3, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "Gm7"	       => [  1, 3, 1, 1, 1, 1,	 3, CHORD_BUILTIN, CHORD_EASY ],
 "Gm/Bb"       => [  3, 2, 2, 1, N, N,	 4, CHORD_BUILTIN, CHORD_HARD ],

 "G#"	       => [  1, 3, 3, 2, 1, 1,	 4, CHORD_BUILTIN, CHORD_EASY ],
 "G#+"	       => [  N, N, 2, 1, 1, 0,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#4"	       => [  1, 3, 3, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "G#7"	       => [  N, N, 1, 1, 1, 2,	 1, CHORD_BUILTIN, CHORD_EASY ],
 "G#sus"       => [  N, N, 1, 1, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#sus4"      => [  N, N, 1, 1, 2, 4,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#maj"       => [  1, 3, 3, 2, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "G#maj7"      => [  N, N, 1, 1, 1, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#dim"       => [  N, N, 0, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#m"	       => [  1, 3, 3, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "G#min"       => [  1, 3, 3, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_HARD ],
 "G#m6"	       => [  N, N, 1, 1, 0, 1,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#m7"	       => [  N, N, 1, 1, 1, 1,	 4, CHORD_BUILTIN, CHORD_EASY ],
 "G#m9maj7"    => [  N, N, 1, 3, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],
 "G#m9(maj7)"  => [  N, N, 1, 3, 0, 3,	 1, CHORD_BUILTIN, CHORD_HARD ],

};
my $song_chords;

sub reset_song_chords {
    $song_chords = {};
}

sub add_song_chord {
    my ( $name, $base, $frets ) = @_;
    $song_chords->{$name} = [ @$frets, $base, CHORD_USER, CHORD_HARD ];
}

sub chord_info {
    my ( $chord ) = @_;
    my @info;
    for ( $song_chords, $chords ) {
	next unless exists($_->{$chord});
	@info = @{ $_->{$chord} };
	last;
    }
    return unless @info;
    {	name    => $chord,
	strings => [ @info[0..5] ],
	base    => $info[6]-1,
	builtin => $info[7] == CHORD_BUILTIN,
	easy    => $info[8] == CHORD_EASY,
    };
}

my $notesS  = [ split( ' ', "A A# B C C# D D# E F F# G G#" ) ];
my $notesF  = [ split( ' ', "A Bb B C Db D Eb E F Gb G Ab" ) ];
my %notes = ( A => 1, H => 2, B => 3, C => 4, D => 6, E => 8, F => 9, G => 11 );

sub transpose {
    my ( $c, $xpose ) = @_;
    return $c unless $xpose;
    return $c unless $c =~ m/
				^ (
				    [CF](?:is|\#)? |
				    [DG](?:is|\#|es|b)? |
				    A(?:is|\#|s|b)? |
				    E(?:s|b)? |
				    B(?:es|b)? |
				    H
				  )
				  (.*)
			    /x;
    my ( $r, $rest ) = ( $1, $2 );
    my $mod = 0;
    $mod-- if $r =~ s/(e?s|b)$//;
    $mod++ if $r =~ s/(is|\#)$//;
    warn("WRONG NOTE: '$c' '$r' '$rest'") unless $r = $notes{$r};
    $r = ($r - 1 + $mod + $xpose) % 12;
    return ( $xpose > 0 ? $notesS : $notesF )->[$r] . $rest;
}

sub dump_chords {
    print( "# CHORD CHART\n",
	   "# Generated by ChordPro ", $App::Music::ChordPro::VERSION, "\n",
	   "# http://www.chordpro.org\n",
	   "#\n",
	   "#            ", " " x 35, "-------strings-------\n",
	   "#       Chord", " " x 35, "E   A   D   G   B   E\n",
	 );
    foreach my $chord ( sort keys %$chords ) {
	my $info = chord_info($chord);
	printf( "{define %-15.15s base-fret %2d    ".
		"frets %3.3s %3.3s %3.3s %3.3s %3.3s %3.3s}\n",
		$info->{name} . ":", $info->{base} + 1,
		map { $_ < 0 ? "X" : $_ } @{ $info->{strings} } );
    }
}

unless ( caller ) {
    use Data::Dumper;
    warn(Dumper(chord_info(shift)));
}