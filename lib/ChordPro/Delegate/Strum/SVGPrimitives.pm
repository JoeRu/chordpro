package ChordPro::Delegate::Strum::SVGPrimitives;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

use ChordPro::Delegate::Strum::Tokens;

sub rest_glyph() {
	my $override = eval { $::config->{gridstrum}->{symbols}->{rest} };
	return $override if defined $override && $override ne '';
	return chr(0x1D13D);
}

sub svg_font_stack() {
	my $override = eval { $::config->{gridstrum}->{font_family} };
	return $override if defined $override && $override ne '';
	return 'Bravura Text, Bravura, Noto Music, Noto Sans Symbols 2, Noto Sans Symbols, Noto Sans, DejaVu Sans, Arial Unicode MS, sans-serif';
}

sub _strum_svg_decorations( %args ) {
	my $x = $args{x};
	my $base_y = $args{base_y} // 0;
	my $info = $args{info} // {};

	my @parts;

	if ( $info->{muted} ) {
		push @parts,
		  sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="9" fill="currentColor">%s</text>',
				  $x, $base_y + 21, ChordPro::Delegate::Strum::Tokens::esc("×"));
	}

	if ( $info->{accent} ) {
		push @parts,
		  sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="9" fill="currentColor">%s</text>',
				  $x, $base_y + 12, ChordPro::Delegate::Strum::Tokens::esc(">"));
	}

	if ( $info->{staccato} ) {
		push @parts,
		  sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="8" fill="currentColor">%s</text>',
				  $x, $base_y + 8, ChordPro::Delegate::Strum::Tokens::esc("•"));
	}

	return @parts;
}

sub draw_rest_svg( %args ) {
	my $x         = $args{x};
	my $base_y    = $args{base_y} // 0;
	my $font_size = $args{font_size} // 14;
	my $glyph     = $args{glyph} // rest_glyph();

	return sprintf(
		'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
		$x, $base_y + 16, $font_size, ChordPro::Delegate::Strum::Tokens::esc($glyph),
	);
}

sub draw_arrow_svg( %args ) {
	my $x         = $args{x};
	my $base_y    = $args{base_y} // 0;
	my $direction = $args{direction};
	my $info      = $args{info} // {};

	my $symbol_cfg = eval { $::config->{gridstrum}->{symbols} } // {};
	my $up_text = eval { $symbol_cfg->{up} } // chr(0x2191);
	my $dn_text = eval { $symbol_cfg->{down} } // chr(0x2193);
	my $glyph = $direction eq 'down' ? $dn_text : $up_text;
	$glyph .= '~' if $info->{arpeggio};

	my @parts = (
		sprintf(
			'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="14" fill="currentColor">%s</text>',
			$x, $base_y + 16, ChordPro::Delegate::Strum::Tokens::esc($glyph),
		)
	);

	push @parts, _strum_svg_decorations(
		x => $x, base_y => $base_y, info => $info);

	return @parts;
}

sub draw_bar_svg( %args ) {
	my $x       = $args{x};
	my $symbol  = $args{symbol} // '|';
	my $label_y = $args{label_y} // 16;

	return sprintf('<text x="%.2f" y="%s" text-anchor="middle" font-size="12" fill="currentColor">%s</text>',
			  $x, $label_y, ChordPro::Delegate::Strum::Tokens::esc(ChordPro::Delegate::Strum::Tokens::bar_unicode($symbol)));
}

sub draw_connector_svg( %args ) {
	my $from_x = $args{from_x};
	my $to_x   = $args{to_x};
	my $y      = $args{y} // 12;
	my $mid_x  = ($from_x + $to_x) / 2;

	return sprintf(
		'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="10" fill="currentColor">%s</text>',
		$mid_x, $y + 3, ChordPro::Delegate::Strum::Tokens::esc("~"));
}

sub draw_pause_svg( %args ) {
	my $x          = $args{x};
	my $y          = $args{y} // 12;
	my $glyph = $args{glyph} // eval { $::config->{gridstrum}->{symbols}->{pause} } // chr(0x2013);

	return sprintf(
		'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="12" fill="currentColor">%s</text>',
		$x, $y + 4, ChordPro::Delegate::Strum::Tokens::esc($glyph));
}

1;
