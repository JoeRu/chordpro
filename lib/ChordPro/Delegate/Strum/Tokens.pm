package ChordPro::Delegate::Strum::Tokens;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;
use URI::Escape ();
use ChordPro::Symbols qw( strum );

sub esc( $text ) {
	return "" unless defined $text;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	$text =~ s/'/&#39;/g;
	$text;
}

sub bar_unicode( $symbol ) {
	return chr(119043) . chr(119042) if $symbol eq '||';
	return chr(119046) if $symbol eq '|:' || $symbol eq '{';
	return chr(119047) if $symbol eq ':|' || $symbol eq '}';
	return chr(119047) . chr(119046) if $symbol eq ':|:' || $symbol eq '}{';
	return chr(119042) if $symbol eq '|.';
	return chr(119040);
}

sub svg_to_data_uri( $svg ) {
	return "" unless defined($svg) && $svg ne '';
	my $escaped = URI::Escape::uri_escape_utf8($svg);
	return "data:image/svg+xml;charset=utf-8,$escaped";
}

sub chord_display_text( $chord ) {
	return "" unless defined $chord;

	my $name = "";

	if ( ref($chord) eq 'HASH' ) {
		$name = $chord->{name} // $chord->{format} // "";
		if ( $name eq "" && ref($chord->{info}) eq 'HASH' ) {
			$name = $chord->{info}->{name} // $chord->{info}->{format} // "";
		}
	}
	elsif ( ref($chord) eq 'ARRAY' ) {
		if ( ref($chord->[2]) eq 'HASH' ) {
			$name = $chord->[2]->{name} // $chord->[2]->{format} // "";
		}
		$name = $chord->[0] // "" if $name eq "";
	}
	elsif ( ref($chord) ) {
		$name = $chord->name if $chord->can('name');
		if ( $name eq "" && $chord->can('chord_display') ) {
			$name = $chord->chord_display;
		}
	}
	else {
		$name = "$chord";
	}

	return $name // "";
}

sub strum_name( $chord ) {
	return lc(chord_display_text($chord));
}

sub normalize_grid_chord_parts( $parts_in ) {
	my @parts = @{ $parts_in // [] };

	if ( @parts > 1 && ( ($parts[0] // '') eq '' ) ) {
		shift @parts;
	}

	@parts = ('') unless @parts;
	return \@parts;
}

sub strum_symbol_info( $chord ) {
	my $raw = strum_name($chord);
	my $token = $raw;
	my %info = (
		raw       => $raw,
		direction => '',
		muted     => 0,
		accent    => 0,
		arpeggio  => 0,
		staccato  => 0,
		rest      => 0,
		code      => '',
		glyph     => '',
	);

	if ( $raw eq '.' ) {
		$info{rest} = 1;
		return \%info;
	}

	return \%info if $raw eq '';

	if ( $token =~ /down/ ) {
		$info{direction} = 'down';
		$token =~ s/down//g;
	}
	elsif ( $token =~ /dn/ ) {
		$info{direction} = 'down';
		$token =~ s/dn//g;
	}
	elsif ( $token =~ /up/ ) {
		$info{direction} = 'up';
		$token =~ s/up//g;
	}
	elsif ( $token =~ /↠|↣|↡|↤|↦|↩|↢|↥/ ) {
		$info{direction} = 'down';
		$token =~ s/↠|↣|↡|↤|↦|↩|↢|↥//g;
	}
	elsif ( $token =~ /←|↖|↓|↑|↔|↙|→|↕/ ) {
		$info{direction} = 'up';
		$token =~ s/←|↖|↓|↑|↔|↙|→|↕//g;
	}
	elsif ( $token =~ /d/ ) {
		$info{direction} = 'down';
		$token =~ s/d//g;
	}
	elsif ( $token =~ /u/ ) {
		$info{direction} = 'up';
		$token =~ s/u//g;
	}

	$info{muted}    = 1 if $token =~ /x/i;
	$info{accent}   = 1 if $token =~ /\+/;
	$info{arpeggio} = 1 if $token =~ /a/;
	$info{staccato} = 1 if $token =~ /s/;

	if ( $info{direction} ne '' ) {
		my $dir = $info{direction} eq 'down' ? 'd' : 'u';
		my $suffix = '';
		# Keep muted/staccato/arpeggio mutually ordered and deterministic.
		if ( $info{muted} ) {
			$suffix = 'x';
		}
		elsif ( $info{arpeggio} ) {
			$suffix = 'a';
		}
		elsif ( $info{staccato} ) {
			$suffix = 's';
		}

		my $code = $dir . $suffix . ( $info{accent} ? '+' : '' );
		$info{code} = $code;
		my $glyph = strum($code);
		$info{glyph} = $glyph if defined($glyph) && $glyph ne '';
	}

	return \%info;
}

1;
