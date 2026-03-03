package ChordPro::Delegate::Strum::StrumlineRenderer;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

use ChordPro::Delegate::Strum::Tokens;
use ChordPro::Delegate::Strum::SVGPrimitives;

sub strum_cells_from_text( $text ) {
	my @cells;
	my $column = 1;
	my @tokens = grep { defined($_) && $_ ne '' } split( /\s+/, ($text // '') );

	for my $token ( @tokens ) {
		if ( $token =~ /^(?:\|\:|\:\||\:\|\:|\|\||\|\.|\||\{|\}|\}\{)$/ ) {
			my $bar_kind = 'single';
			$bar_kind = 'double' if $token eq '||';
			$bar_kind = 'repeat-start' if $token eq '|:' || $token eq '{';
			$bar_kind = 'repeat-end' if $token eq ':|' || $token eq '}';
			$bar_kind = 'repeat-both' if $token eq ':|:' || $token eq '}{';
			$bar_kind = 'end' if $token eq '|.';
			push @cells, {
				type => 'bar',
				column => $column,
				bar_kind => $bar_kind,
				bar_symbol => $token,
			};
			$column++;
			next;
		}

		my @parts = split( /~/, $token, -1 );
		my $had_leading_tilde = ( @parts > 1 && ( ($parts[0] // '') eq '' ) ) ? 1 : 0;
		if ( $had_leading_tilde ) {
			shift @parts;
		}
		my @part_info = map { ChordPro::Delegate::Strum::Tokens::strum_symbol_info({ name => $_ }) } @parts;

		if ( $had_leading_tilde ) {
			push @cells, {
				type => 'cell',
				column => $column,
				direction => '',
				muted => 0, accent => 0, arpeggio => 0, staccato => 0,
				rest => 1,
				pause => 0,
				connect_left => 0,
			};
			$column++;
		}

		for my $idx (0 .. $#parts) {
			my $info = $part_info[$idx] // {};
			my $prev_info = $idx > 0 ? ($part_info[$idx - 1] // {}) : {};
			my $raw = $info->{raw} // '';

			my $is_rest = $info->{rest} // 0;
			if ( !$is_rest && $raw eq '' && @parts > 1 ) {
				$is_rest = 1 if $idx > 0 && (($prev_info->{raw}//'') ne '');
			}

			my $is_pause = 0;
			if ( !$is_rest ) {
				$is_pause = ($raw eq '' && ($idx == 0 || (($prev_info->{raw}//'') ne ''))) ? 1 : 0;
			}
			my $connect_left = (($info->{direction}//'') ne '' && ($prev_info->{direction}//'') ne '') ? 1 : 0;

			push @cells, {
				type => 'cell',
				column => $column,
				direction => $info->{direction},
				muted => $info->{muted},
				accent => $info->{accent},
				arpeggio => $info->{arpeggio},
				staccato => $info->{staccato},
				rest => $is_rest,
				pause => $is_pause,
				connect_left => $connect_left,
			};
			$column++;
		}
	}

	my $columns = $column - 1;
	$columns = 1 if $columns < 1;
	return (\@cells, $columns);
}

sub strumline_svg_from_text( %args ) {
	my ($cells, $columns) = strum_cells_from_text($args{text} // '');
	return strumline_svg(
		cells => $cells,
		columns => $args{columns} // $columns,
		show_bars => exists $args{show_bars} ? $args{show_bars} : 1,
		cell_width => $args{cell_width} // 24,
		height => $args{height} // 26,
		stroke_width => $args{stroke_width} // 1.6,
	);
}

sub strumline_svg( %args ) {
	my $cells      = $args{cells} // [];
	my $columns    = $args{columns} // scalar(@$cells) || 1;
	my $show_bars  = $args{show_bars} // 0;
	my $cell_width = $args{cell_width} // 24;
	my $height     = $args{height} // 26;
	my $stroke     = $args{stroke_width} // 1.6;
	my $tight_pair_step = $args{tight_pair_step} // 0.42;

	$columns = 1 if $columns < 1;
	my $width = $columns * $cell_width;

	my @parts;

	my $last_arrow_x;
	for my $cell ( @$cells ) {
		my $column = $cell->{column} // 1;
		my $x = ($column - 0.5) * $cell_width;

		if ( ($cell->{type} // '') eq 'bar' ) {
			$last_arrow_x = undef;
			next unless $show_bars;
			push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_bar_svg(
				x => $x, kind => $cell->{bar_kind},
				symbol => $cell->{bar_symbol});
			next;
		}

		if ( $cell->{rest} ) {
			push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_rest_svg( x => $x, base_y => 0 );
			$last_arrow_x = undef;
			next;
		}

		if ( $cell->{pause} ) {
			push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_pause_svg( x => $x, cell_width => $cell_width );
			$last_arrow_x = undef;
			next;
		}

		my $direction = $cell->{direction} // '';
		unless ( $direction ) {
			$last_arrow_x = undef;
			next;
		}

		if ( $cell->{connect_left} && defined $last_arrow_x ) {
			$x = $last_arrow_x + ($cell_width * $tight_pair_step);
		}

		if ( $cell->{connect_left} && defined $last_arrow_x ) {
			push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_connector_svg(
				from_x => $last_arrow_x, to_x => $x);
		}

		push @parts, ChordPro::Delegate::Strum::SVGPrimitives::draw_arrow_svg(
			x => $x, base_y => 0, direction => $direction,
			stroke_width => $stroke,
			info => {
				muted    => $cell->{muted},
				accent   => $cell->{accent},
				arpeggio => $cell->{arpeggio},
				staccato => $cell->{staccato},
			},
		);

		$last_arrow_x = $x;
	}

	return sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %d" width="%.2f" height="%d" aria-hidden="true">%s</svg>',
		$width, $height, $width, $height, join('', @parts));
}

1;
