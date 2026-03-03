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

sub _strum_svg_decorations( %args ) {
	my $x = $args{x};
	my $base_y = $args{base_y} // 0;
	my $info = $args{info} // {};

	my @parts;

	if ( $info->{muted} ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.4"/>',
				  $x - 3.5, $base_y + 22, $x + 3.5, $base_y + 17),
		  sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.4"/>',
				  $x - 3.5, $base_y + 17, $x + 3.5, $base_y + 22);
	}

	if ( $info->{accent} ) {
		push @parts,
		  sprintf('<polyline points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="none" stroke="currentColor" stroke-width="1.4"/>',
				  $x - 3.5, $base_y + 21,
				  $x + 3.5, $base_y + 18,
				  $x - 3.5, $base_y + 15);
	}

	if ( $info->{staccato} ) {
		push @parts,
		  sprintf('<circle cx="%.2f" cy="%.2f" r="1.4" fill="currentColor"/>',
				  $x, $base_y + 12);
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
	my $stroke    = $args{stroke_width} // 1.6;
	my $info      = $args{info} // {};
	my $arpeggio  = $info->{arpeggio} // 0;

	my $symbol_cfg = eval { $::config->{gridstrum}->{symbols} } // {};
	my $text_mode = (eval { $symbol_cfg->{mode} } // '') eq 'text' ? 1 : 0;
	my $up_text = eval { $symbol_cfg->{up} } // chr(0x2191);
	my $dn_text = eval { $symbol_cfg->{down} } // chr(0x2193);
	my $simple = !($info->{muted} || $info->{accent} || $info->{arpeggio} || $info->{staccato});

	if ( $simple && ($text_mode || defined(eval { $symbol_cfg->{up} }) || defined(eval { $symbol_cfg->{down} })) ) {
		my $glyph = $direction eq 'down' ? $dn_text : $up_text;
		return sprintf(
			'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="14" fill="currentColor">%s</text>',
			$x, $base_y + 16, ChordPro::Delegate::Strum::Tokens::esc($glyph),
		);
	}

	my ($y1, $y2) = $direction eq 'down'
		? ($base_y + 4, $base_y + 20)
		: ($base_y + 20, $base_y + 4);
	my $dash = $arpeggio ? ' stroke-dasharray="2 2"' : '';

	my @parts;
	my $sw_fmt = $stroke == int($stroke) ? '%.0f' : '%g';
	push @parts, sprintf(
		'<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="' . sprintf($sw_fmt, $stroke) . '"%s/>',
		$x, $y1, $x, $y2, $dash);

	my $tw = 3.2;
	my $th = 3.6;
	if ( $direction eq 'down' ) {
		push @parts, sprintf(
			'<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>',
			$x, $y2 + $th, $x - $tw, $y2 - $th, $x + $tw, $y2 - $th);
	}
	else {
		push @parts, sprintf(
			'<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>',
			$x, $y2 - $th, $x - $tw, $y2 + $th, $x + $tw, $y2 + $th);
	}

	push @parts, _strum_svg_decorations(
		x => $x, base_y => $base_y, info => $info);

	return @parts;
}

sub draw_bar_svg( %args ) {
	my $x       = $args{x};
	my $kind    = $args{kind} // 'single';
	my $symbol  = $args{symbol} // '|';
	my $top     = $args{top} // 3;
	my $bottom  = $args{bottom} // 23;
	my $label_y = $args{label_y} // 26;

	my $left  = $x - 1.3;
	my $right = $x + 1.3;
	my $dot_offset = 3.0;

	my @parts;

	if ( $kind eq 'double' ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $left, $top, $left, $bottom),
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $right, $top, $right, $bottom);
	}
	elsif ( $kind eq 'repeat-start' ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1.2"/>', $left, $top, $left, $bottom),
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $right, $top, $right, $bottom),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $right + $dot_offset, $top + 7),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $right + $dot_offset, $top + 13);
	}
	elsif ( $kind eq 'repeat-end' ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $left, $top, $left, $bottom),
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1.2"/>', $right, $top, $right, $bottom),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $left - $dot_offset, $top + 7),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $left - $dot_offset, $top + 13);
	}
	elsif ( $kind eq 'repeat-both' ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $left, $top, $left, $bottom),
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $right, $top, $right, $bottom),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $left - $dot_offset, $top + 7),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $left - $dot_offset, $top + 13),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $right + $dot_offset, $top + 7),
		  sprintf('<circle cx="%.2f" cy="%s" r="0.9" fill="currentColor"/>', $right + $dot_offset, $top + 13);
	}
	elsif ( $kind eq 'end' ) {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $left, $top, $left, $bottom),
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1.8"/>', $right, $top, $right, $bottom);
	}
	else {
		push @parts,
		  sprintf('<line x1="%.2f" y1="%s" x2="%.2f" y2="%s" stroke="currentColor" stroke-width="1"/>', $x, $top, $x, $bottom);
	}

	push @parts,
	  sprintf('<text x="%.2f" y="%s" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
			  $x, $label_y, ChordPro::Delegate::Strum::Tokens::esc(ChordPro::Delegate::Strum::Tokens::bar_unicode($symbol)));

	return @parts;
}

sub draw_connector_svg( %args ) {
	my $from_x = $args{from_x};
	my $to_x   = $args{to_x};
	my $y      = $args{y} // 12;
	my $offset = $args{offset} // 2.8;

	return sprintf(
		'<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>',
		$from_x + $offset, $y, $to_x - $offset, $y);
}

sub draw_pause_svg( %args ) {
	my $x          = $args{x};
	my $y          = $args{y} // 12;
	my $cell_width = $args{cell_width} // 24;

	return sprintf(
		'<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>',
		$x - ($cell_width * 0.12), $y, $x + ($cell_width * 0.12), $y);
}

1;
