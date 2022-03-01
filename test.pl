use strict;
use warnings;
use utf8;

use lib "/workspaces/chordpro/lib/App/Music/ChordPro/";
use lib "/workspaces/chordpro/lib/App/Music/ChordPro/Output/";
use App::Music::ChordPro::Testing;

my @argv = ( "--no-default-configs", "/workspaces/chordpro/test_1.cho","--output=/workspaces/chordpro/test.md" );


::run();
