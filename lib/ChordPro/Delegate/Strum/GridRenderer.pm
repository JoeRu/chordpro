package ChordPro::Delegate::Strum::GridRenderer;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

use ChordPro::Delegate::Strum::Tokens;
use ChordPro::Delegate::Strum::SVGPrimitives;

sub grid_block_svg( %args ) {
	my $rows = $args{rows} // [];
	my $cell_width = $args{cell_width} // 24;
	my $row_height = $args{row_height} // 26;
	my $row_gap = $args{row_gap} // 6;
	my $font_size = $args{font_size} // 12;
	my $tight_pair_step = $args{tight_pair_step} // 0.42;

	my $compute_columns = sub ($tokens, $is_strumline = 0) {
		my $cols = 0;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				if ($is_strumline) {
					$cols += 1;
				}
				else {
					my $parts = ChordPro::Delegate::Strum::Tokens::normalize_grid_chord_parts( $token->{chords} );
					my $n = scalar(@$parts);
					$n = 1 if $n < 1;
					$cols += $n;
				}
			}
			else {
				$cols++;
			}
		}
		$cols = 1 if $cols < 1;
		return $cols;
	};

	my $columns = $args{columns};
	if (!defined $columns || $columns < 1) {
		$columns = 1;
		for my $row (@$rows) {
			my $is_strum = (($row->{type} // '') eq 'strumline') ? 1 : 0;
			my $line_cols = $compute_columns->($row->{tokens} // [], $is_strum);
			$columns = $line_cols if $line_cols > $columns;
		}
	}

	my $bar_columns_for = sub ($tokens, $is_strumline = 0) {
		my @bars;
		my $col = 1;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				if ($is_strumline) {
					$col += 1;
				}
				else {
					my $parts = ChordPro::Delegate::Strum::Tokens::normalize_grid_chord_parts( $token->{chords} );
					my $n = scalar(@$parts);
					$n = 1 if $n < 1;
					$col += $n;
				}
				next;
			}
			if ($class eq 'bar') {
				push @bars, $col;
			}
			$col++;
		}
		return \@bars;
	};

	my @canonical_bar_columns;
	for my $row (@$rows) {
		my $is_strum = (($row->{type} // '') eq 'strumline') ? 1 : 0;
		my $bars = $bar_columns_for->($row->{tokens} // [], $is_strum);
		next unless @$bars;
		@canonical_bar_columns = @$bars;
		last if (($row->{type} // '') eq 'gridline');
	}

	my $width = $columns * $cell_width;
	my $height = scalar(@$rows) * $row_height + (scalar(@$rows) - 1) * $row_gap;
	$height = $row_height if $height < $row_height;

	my @parts;
	for my $row_idx (0 .. $#$rows) {
		my $row = $rows->[$row_idx] // {};
		my $type = $row->{type} // 'gridline';
		my $tokens = $row->{tokens} // [];
		my $base_y = $row_idx * ($row_height + $row_gap);
		my $bar_top = $base_y + 3;
		my $bar_bottom = $base_y + $row_height - 3;
		my $bar_label_y = $base_y + $row_height;

		my $column = 1;
		my $last_arrow_x;
		my $bar_index = 0;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';

			if ($class eq 'chords') {
				my $parts_raw = $token->{chords} // [];
				my $had_leading_empty = ( @$parts_raw > 1 && ( ($parts_raw->[0] // '') eq '' ) ) ? 1 : 0;
				my $parts_in = ChordPro::Delegate::Strum::Tokens::normalize_grid_chord_parts( $parts_raw );
				my $prev_arrow_x;
				my $prev_info;
				my $is_strum = ($type eq 'strumline') ? 1 : 0;
				my $base_x = ($column - 0.5) * $cell_width;

				if ($had_leading_empty) {
					push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_rest_svg(
						x => $base_x, base_y => $base_y, font_size => $font_size);
				}

				for my $idx (0 .. $#$parts_in) {
					my $part = $parts_in->[$idx];
					my $x = $base_x;
					if ($is_strum) {
						my $info = ChordPro::Delegate::Strum::Tokens::strum_symbol_info($part);
						if ($had_leading_empty && $idx == 0 && ($info->{direction}//'') ne '') {
							$x = $base_x + ($cell_width * $tight_pair_step);
						}
						elsif (defined $prev_arrow_x
							&& (($prev_info // {})->{direction} // '') ne ''
							&& (($info->{direction}//'') ne '')) {
							$x = $prev_arrow_x + ($cell_width * $tight_pair_step);
						}

						if ( $info->{rest} ) {
							push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_rest_svg(
								x => $x, base_y => $base_y, font_size => $font_size);
							$last_arrow_x = undef;
							$prev_arrow_x = undef;
						}
						elsif (($info->{direction}//'') ne '') {
							push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_arrow_svg(
								x => $x, base_y => $base_y,
								direction => $info->{direction},
								info => $info);
							$last_arrow_x = $x;
							$prev_arrow_x = $x;
						}
						$prev_info = $info;
					}
					else {
						my $label = ChordPro::Delegate::Strum::Tokens::chord_display_text($part);
						$label = '' if $label eq '.';
						if ($had_leading_empty && $idx == 0 && $label ne '') {
							$x = $base_x + ($cell_width * $tight_pair_step);
						}
						push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
							$x, $base_y + 16, $font_size, ChordPro::Delegate::Strum::Tokens::esc($label));
					}
					$column++ unless $is_strum;
				}
				$column++ if $is_strum;
				next;
			}

			my $x = ($column - 0.5) * $cell_width;
			if ($class eq 'bar') {
				my $bar_col = $canonical_bar_columns[$bar_index] // $column;
				$x = ($bar_col - 0.5) * $cell_width;
				$bar_index++;
				my $symbol = $token->{symbol} // '|';
				push @parts, sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1"/>',
					$x, $bar_top, $x, $bar_bottom);
				if ($type eq 'gridline') {
					push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, $bar_label_y, ChordPro::Delegate::Strum::Tokens::esc(ChordPro::Delegate::Strum::Tokens::bar_unicode($symbol)));
				}
				$last_arrow_x = undef;
				$column++;
				next;
			}

			if ($type eq 'gridline') {
				my $text = '';
				if ($class eq 'chord') {
					$text = ChordPro::Delegate::Strum::Tokens::chord_display_text($token->{chord});
				}
				elsif ($class eq 'repeat1' || $class eq 'repeat2' || $class eq 'slash' || $class eq 'space') {
					$text = $token->{symbol} // '';
				}
				push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
					$x, $base_y + 16, $font_size, ChordPro::Delegate::Strum::Tokens::esc($text));
			}
			else {
				my $info = $class eq 'chord' ? ChordPro::Delegate::Strum::Tokens::strum_symbol_info($token->{chord}) : {};
				if ( $info->{rest} ) {
					push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_rest_svg(
						x => $x, base_y => $base_y, font_size => $font_size);
					$last_arrow_x = undef;
				}
				elsif (($info->{direction}//'') ne '') {
					push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_arrow_svg(
						x => $x, base_y => $base_y,
						direction => $info->{direction},
						info => $info);
					if ( $last_arrow_x ) {
						push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_connector_svg(
							from_x => $last_arrow_x, to_x => $x,
							y => $base_y + 12);
					}
					$last_arrow_x = $x;
				}
			}

			$column++;
		}
	}

	return sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %.2f" width="%.2f" height="%.2f" aria-hidden="true">%s</svg>',
		$width, $height, $width, $height, join('', @parts));
}

1;
