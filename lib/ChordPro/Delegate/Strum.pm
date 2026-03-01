#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;
use URI::Escape ();

package ChordPro::Delegate::Strum;

=for docs

** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL **

Experimental delegate to produce a 'strum' image.

    bpm [ BPM ]
    time [ n/d ]

    d = down
    u = up
    xd = muted down
    xu = muted up
    +d = accented down
    +u = accented up
    ad = arpeggio down
    au = arpeggio up

Config:

delegate.strum {
    type     : image
    module   : Strum
    handler  : strum2xo
    preamble : []
}

=cut

use ChordPro::Utils qw(dimension maybe);

sub DEBUG() { $::config->{debug}->{x2} }

sub strum2xo( $song, %args ) {
    my $elt = $args{elt};
    my $kv = { %{$elt->{opts}} };
    my $ps = $song->{_ps};
    my $pr = $ps->{pr};
	unless ( $pr
			 && $pr->{pdfgfx}
			 && $pr->{pdfgfx}->{' apipage'}
			 && $pr->{pdfgfx}->{' apipage'}->{' api'} ) {
		return strum2html( $song, %args );
	}
    my $bpm = 4;
    if ( ($song->{meta}->{time}->[0] // "4/4") =~ /^\s*(\d+)\s*\/\s*(\d+)\s*$/ ) { 
	$bpm = $1;
    }

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
    }

    my $xo = $pr->{pdfgfx}->{' apipage'}->{' api'}->xo_form;
    my @xo;
    my $txtfont = ($ps->{fonts}->{strum}//$ps->{fonts}->{text})->{fd};

    for ( @{ $elt->{data} } ) {

	my $s = Strum->new( data => $_ );

	push( @xo, $s->build( gfx     => $pr->{pdfgfx},
			      color   => $kv->{color} // $pr->_fgcolor,
			      txtfont => $txtfont,
			      size    => $kv->{size} || 30,
			      bpm     => $bpm,
			      tuplet  => $kv->{tuplet} || 1,
			    ) );
    }
    $xo = $xo[0];

    # Finish.
    my $scale;
    my $design_scale;
    $kv->{scale} = dimension( $kv->{scale}//1, width => 1 );
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type    => "image",
	    line    => $elt->{line},
	    subtype => "xform",
	    data    => $xo,
	    width   => $xo->width,
	    height  => $xo->height,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe spread       => $kv->{spread},
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

sub _esc( $text ) {
		return "" unless defined $text;
		$text =~ s/&/&amp;/g;
		$text =~ s/</&lt;/g;
		$text =~ s/>/&gt;/g;
		$text =~ s/"/&quot;/g;
		$text =~ s/'/&#39;/g;
		$text;
}

sub _bar_unicode( $symbol ) {
	return chr(119043) . chr(119042) if $symbol eq '||';
	return chr(119046) if $symbol eq '|:' || $symbol eq '{';
	return chr(119047) if $symbol eq ':|' || $symbol eq '}';
	return chr(119047) . chr(119046) if $symbol eq ':|:' || $symbol eq '}{';
	return chr(119042) if $symbol eq '|.';
	return chr(119040);
}

sub _svg_to_data_uri( $svg ) {
	return "" unless defined($svg) && $svg ne '';
	my $escaped = URI::Escape::uri_escape_utf8($svg);
	return "data:image/svg+xml;charset=utf-8,$escaped";
}

sub _chord_display_text( $chord ) {
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

sub _strum_name( $chord ) {
	return lc(_chord_display_text($chord));
}

sub strum_symbol_info( $chord ) {
	my $raw = _strum_name($chord);
	my %info = (
		raw      => $raw,
		direction => '',
		muted    => 0,
		accent   => 0,
		arpeggio => 0,
	);

	return \%info if $raw eq '' || $raw eq '.';

	$info{muted}    = 1 if $raw =~ /^x/;
	$info{accent}   = 1 if $raw =~ /^\+/;
	$info{arpeggio} = 1 if $raw =~ /^a/;

	if ( $raw =~ /(?:dn|down|d|↠)$/ ) {
		$info{direction} = 'down';
	}
	elsif ( $raw =~ /(?:up|u|←)$/ ) {
		$info{direction} = 'up';
	}

	return \%info;
}

sub _strum_cells_from_text( $text ) {
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
		my @part_info = map { strum_symbol_info({ name => $_ }) } @parts;
		for my $idx (0 .. $#parts) {
			my $info = $part_info[$idx] // {};
			my $prev_info = $idx > 0 ? ($part_info[$idx - 1] // {}) : {};
			my $raw = $info->{raw} // '';
			my $is_pause = ($raw eq '' && ($idx == 0 || (($prev_info->{raw}//'') ne ''))) ? 1 : 0;
			my $connect_left = (($info->{direction}//'') ne '' && ($prev_info->{direction}//'') ne '') ? 1 : 0;

			push @cells, {
				type => 'cell',
				column => $column,
				direction => $info->{direction},
				muted => $info->{muted},
				accent => $info->{accent},
				arpeggio => $info->{arpeggio},
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
	my ($cells, $columns) = _strum_cells_from_text($args{text} // '');
	return strumline_svg(
		cells => $cells,
		columns => $args{columns} // $columns,
		show_bars => exists $args{show_bars} ? $args{show_bars} : 1,
		cell_width => $args{cell_width} // 24,
		height => $args{height} // 26,
		stroke_width => $args{stroke_width} // 1.6,
	);
}

sub grid_block_svg( %args ) {
	my $rows = $args{rows} // [];
	my $cell_width = $args{cell_width} // 24;
	my $row_height = $args{row_height} // 26;
	my $row_gap = $args{row_gap} // 6;
	my $font_size = $args{font_size} // 12;
	my $tight_pair_step = $args{tight_pair_step} // 0.58;

	my $compute_columns = sub ($tokens) {
		my $cols = 0;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				my $parts = $token->{chords} // [];
				my $n = scalar(@$parts);
				$n = 1 if $n < 1;
				$cols += $n;
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
			my $line_cols = $compute_columns->($row->{tokens} // []);
			$columns = $line_cols if $line_cols > $columns;
		}
	}

	my $bar_columns_for = sub ($tokens) {
		my @bars;
		my $col = 1;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				my $parts = $token->{chords} // [];
				my $n = scalar(@$parts);
				$n = 1 if $n < 1;
				$col += $n;
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
		my $bars = $bar_columns_for->($row->{tokens} // []);
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

		my $column = 1;
		my $last_arrow_x;
		my $bar_index = 0;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';

			if ($class eq 'chords') {
				my $parts_in = $token->{chords} // [];
				my $prev_arrow_x;
				my $prev_info;
				for my $idx (0 .. $#$parts_in) {
					my $part = $parts_in->[$idx];
					my $x = ($column - 0.5) * $cell_width;
					if ($type eq 'strumline') {
						my $info = strum_symbol_info($part);
						if (defined $prev_arrow_x
							&& (($prev_info // {})->{direction} // '') ne ''
							&& (($info->{direction}//'') ne '')) {
							$x = $prev_arrow_x + ($cell_width * $tight_pair_step);
						}
						if (($info->{direction}//'') ne '') {
							my ($y1, $y2) = $info->{direction} eq 'down'
								? ($base_y + 4, $base_y + 20)
								: ($base_y + 20, $base_y + 4);
							push @parts, sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.6"/>', $x, $y1, $x, $y2);
							if ($info->{direction} eq 'down') {
								push @parts, sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>', $x, $y2 + 3.6, $x - 3.2, $y2 - 3.6, $x + 3.2, $y2 - 3.6);
							}
							else {
								push @parts, sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>', $x, $y2 - 3.6, $x - 3.2, $y2 + 3.6, $x + 3.2, $y2 + 3.6);
							}
							$last_arrow_x = $x;
							$prev_arrow_x = $x;
						}
						$prev_info = $info;
					}
					else {
						my $label = _chord_display_text($part);
						$label = '' if $label eq '.';
						push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
							$x, $base_y + 16, $font_size, _esc($label));
					}
					$column++;
				}
				next;
			}

			my $x = ($column - 0.5) * $cell_width;
			if ($class eq 'bar') {
				my $bar_col = $canonical_bar_columns[$bar_index] // $column;
				$x = ($bar_col - 0.5) * $cell_width;
				$bar_index++;
				my $symbol = $token->{symbol} // '|';
				push @parts, sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1"/>',
					$x, $base_y + 3, $x, $base_y + $row_height - 3);
				if ($type eq 'gridline') {
					push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, $base_y + $row_height, _esc(_bar_unicode($symbol)));
				}
				$last_arrow_x = undef;
				$column++;
				next;
			}

			if ($type eq 'gridline') {
				my $text = '';
				if ($class eq 'chord') {
					$text = _chord_display_text($token->{chord});
				}
				elsif ($class eq 'repeat1' || $class eq 'repeat2' || $class eq 'slash' || $class eq 'space') {
					$text = $token->{symbol} // '';
				}
				push @parts, sprintf('<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
					$x, $base_y + 16, $font_size, _esc($text));
			}
			else {
				my $info = $class eq 'chord' ? strum_symbol_info($token->{chord}) : {};
				if (($info->{direction}//'') ne '') {
					my ($y1, $y2) = $info->{direction} eq 'down'
						? ($base_y + 4, $base_y + 20)
						: ($base_y + 20, $base_y + 4);
					push @parts, sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.6"/>', $x, $y1, $x, $y2);
					if ($info->{direction} eq 'down') {
						push @parts, sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>', $x, $y2 + 3.6, $x - 3.2, $y2 - 3.6, $x + 3.2, $y2 - 3.6);
					}
					else {
						push @parts, sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>', $x, $y2 - 3.6, $x - 3.2, $y2 + 3.6, $x + 3.2, $y2 + 3.6);
					}
					if ( $last_arrow_x ) {
						push @parts, sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>',
							$last_arrow_x + 2.8, $base_y + 12, $x - 2.8, $base_y + 12);
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

sub strumline_svg( %args ) {
	my $cells      = $args{cells} // [];
	my $columns    = $args{columns} // scalar(@$cells) || 1;
	my $show_bars  = $args{show_bars} // 0;
	my $cell_width = $args{cell_width} // 24;
	my $height     = $args{height} // 26;
	my $stroke     = $args{stroke_width} // 1.6;

	$columns = 1 if $columns < 1;
	my $width = $columns * $cell_width;

	my @parts;
	my $bar_unicode = sub ($symbol) {
		return chr(119043) . chr(119042) if $symbol eq '||';
		return chr(119046) if $symbol eq '|:' || $symbol eq '{';
		return chr(119047) if $symbol eq ':|' || $symbol eq '}';
		return chr(119047) . chr(119046) if $symbol eq ':|:' || $symbol eq '}{';
		return chr(119042) if $symbol eq '|.';
		return chr(119040);
	};

	my $draw_bar = sub ($x, $kind, $symbol) {
		$kind //= 'single';
		$symbol //= '|';

		my $left = $x - 1.3;
		my $right = $x + 1.3;
		my $dot_offset = 3.0;

		if ( $kind eq 'double' ) {
			return (
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $left, $left),
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $right, $right),
				sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, _esc($bar_unicode->($symbol))),
			);
		}

		if ( $kind eq 'repeat-start' ) {
			return (
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1.2"/>', $left, $left),
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $right, $right),
				sprintf('<circle cx="%.2f" cy="10" r="0.9" fill="currentColor"/>', $right + $dot_offset),
				sprintf('<circle cx="%.2f" cy="16" r="0.9" fill="currentColor"/>', $right + $dot_offset),
				sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, _esc($bar_unicode->($symbol))),
			);
		}

		if ( $kind eq 'repeat-end' ) {
			return (
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $left, $left),
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1.2"/>', $right, $right),
				sprintf('<circle cx="%.2f" cy="10" r="0.9" fill="currentColor"/>', $left - $dot_offset),
				sprintf('<circle cx="%.2f" cy="16" r="0.9" fill="currentColor"/>', $left - $dot_offset),
				sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, _esc($bar_unicode->($symbol))),
			);
		}

		if ( $kind eq 'repeat-both' ) {
			return (
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $left, $left),
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $right, $right),
				sprintf('<circle cx="%.2f" cy="10" r="0.9" fill="currentColor"/>', $left - $dot_offset),
				sprintf('<circle cx="%.2f" cy="16" r="0.9" fill="currentColor"/>', $left - $dot_offset),
				sprintf('<circle cx="%.2f" cy="10" r="0.9" fill="currentColor"/>', $right + $dot_offset),
				sprintf('<circle cx="%.2f" cy="16" r="0.9" fill="currentColor"/>', $right + $dot_offset),
				sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, _esc($bar_unicode->($symbol))),
			);
		}

		if ( $kind eq 'end' ) {
			return (
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $left, $left),
				sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1.8"/>', $right, $right),
				sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
						$x, _esc($bar_unicode->($symbol))),
			);
		}

		return (
			sprintf('<line x1="%.2f" y1="3" x2="%.2f" y2="23" stroke="currentColor" stroke-width="1"/>', $x, $x),
			sprintf('<text x="%.2f" y="26" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
					$x, _esc($bar_unicode->($symbol))),
		);
	};

	my $last_arrow_x;
	for my $cell ( @$cells ) {
		my $column = $cell->{column} // 1;
		my $x = ($column - 0.5) * $cell_width;

		if ( ($cell->{type} // '') eq 'bar' ) {
			$last_arrow_x = undef;
			next unless $show_bars;
			push @parts, $draw_bar->($x, $cell->{bar_kind}, $cell->{bar_symbol});
			next;
		}

		if ( $cell->{pause} ) {
			push @parts,
			  sprintf('<line x1="%.2f" y1="12" x2="%.2f" y2="12" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>',
					  $x - ($cell_width * 0.12), $x + ($cell_width * 0.12));
			$last_arrow_x = undef;
			next;
		}

		my $direction = $cell->{direction} // '';
		unless ( $direction ) {
			$last_arrow_x = undef;
			next;
		}

		if ( $cell->{connect_left} && defined $last_arrow_x ) {
			push @parts,
			  sprintf('<line x1="%.2f" y1="12" x2="%.2f" y2="12" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>',
					  $last_arrow_x + 2.8, $x - 2.8);
		}

		my ($y1, $y2) = $direction eq 'down' ? (4, 20) : (20, 4);
		my $dash = ($cell->{arpeggio} // 0) ? ' stroke-dasharray="2 2"' : '';

		push @parts,
		  sprintf('<line x1="%.2f" y1="%d" x2="%.2f" y2="%d" stroke="currentColor" stroke-width="%.2f"%s/>',
				  $x, $y1, $x, $y2, $stroke, $dash);

		my $tw = 3.2;
		my $th = 3.6;
		if ( $direction eq 'down' ) {
			push @parts,
			  sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>',
					  $x, $y2 + $th,
					  $x - $tw, $y2 - $th,
					  $x + $tw, $y2 - $th);
		}
		else {
			push @parts,
			  sprintf('<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="currentColor"/>',
					  $x, $y2 - $th,
					  $x - $tw, $y2 + $th,
					  $x + $tw, $y2 + $th);
		}

		if ( $cell->{muted} ) {
			push @parts,
			  sprintf('<line x1="%.2f" y1="22" x2="%.2f" y2="17" stroke="currentColor" stroke-width="1.4"/>', $x - 3.5, $x + 3.5),
			  sprintf('<line x1="%.2f" y1="17" x2="%.2f" y2="22" stroke="currentColor" stroke-width="1.4"/>', $x - 3.5, $x + 3.5);
		}
		elsif ( $cell->{accent} ) {
			push @parts,
			  sprintf('<polyline points="%.2f,21 %.2f,18 %.2f,15" fill="none" stroke="currentColor" stroke-width="1.4"/>',
					  $x - 3.5, $x + 3.5, $x - 3.5);
		}

		$last_arrow_x = $x;
	}

	return sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %d" width="%.2f" height="%d" aria-hidden="true">%s</svg>',
				   $width, $height, $width, $height, join('', @parts));
}

sub strum2html( $song, %args ) {
	my $elt = $args{elt};
	my @data = grep { defined($_) && /\S/ } @{ $elt->{data} // [] };

	my @imgs;
	for my $line (@data) {
		my $svg = strumline_svg_from_text(
			text => $line,
			show_bars => 1,
		);
		my $uri = _svg_to_data_uri($svg);
		push @imgs, qq{<img class="cp-grid-strum-svg cp-standalone-strum-svg" src="} . _esc($uri) . qq{" alt="" />};
	}

	my $body = qq{<div class="cp-delegate cp-delegate-strum cp-delegate-strum-block">};
	if (@imgs) {
		$body .= join('', @imgs);
	}
	else {
		$body .= qq{<span class="cp-strum-empty">(empty strum)</span>};
	}
	$body .= "</div>\n";

	return {
		type => "html",
		line => $elt->{line},
		data => $body,
	};
}

# Pre-scan.
sub options( $data ) { {} }

use Object::Pad;

################

class Strum;

sub DEBUG() { $::config->{debug}->{x2} }
use Ref::Util qw( is_arrayref );
use ChordPro::Utils qw(maybe);

field $data    :param;

# These are initialized by 'build' method.
field $do;			# drawing object
field $size;
field $color;
field $tuplet;
field $bpm;

BUILD {
    if ( $data =~ /-(\d+)(t?)\s*$/ ) {
	$bpm = 4;
	$tuplet = 1;#$1/$bpm;
	$tuplet *= 3 if $2;
	my @d;
	while ( $data =~ m/([udUdMmAa r])/g ) {
	    my $c = $1;
	    push( @d, {       arrow  =>
			      ( $c =~ /[r ]/ ? " "
				: ( !!($c =~ /[uUma]/) ? "u" : "d" ) ),
			maybe mute   => !!( $c =~ /m/i ),
			maybe arpeggio => !!( $c =~ /a/i ),
		      } );
	}
	$data = \@d;
    }
    else {
	my @d;
	while ( $data =~ m/([x+]?)(a?)([ud]| )/g ) {
	    push( @d, {       arrow  => $3,
			maybe mute   => ($1 eq 'x'),
			maybe accent => ($1 eq '+'),
			maybe arpeggio => ($2 eq 'a'),
		      } );
	}
	$data = \@d;
    }
};

method build( %args ) {

    my $missing = "";
    for ( qw( gfx size ) ) {
	$missing .= "$_ " unless defined $args{$_};
    }
    die("Missing arguments to Strum::build: $missing\n") if $missing;

    my $gfx  = $args{gfx};
    $size = $args{size};
    my $x = 0;
    my $y = 0;
    $do = DrawingObject->new( gfx     => $gfx,
			      size    => $size,
			      txtfont => $args{txtfont},
			      color   => $color = $args{color} // "black",
			    );
    my $lw  = $do->lw;
    my $hw  = $do->hw;
    my $hhw = $do->hhw;
    my $xo  = $do->newxo;
    my $i   = 0;
    my ( $w, $h );

    while ( 1 ) {
	$i++;
	$x =
	$do->strum( $x, $y, $data,
		    bpm => $bpm || $args{bpm} || 4,
		    tuplet => $tuplet || $args{tuplet} || 1,
		  );
	last;
    }

    $xo->bbox( -$lw/2,
	       -$hw-$hhw-$lw/2,
	       $x+$lw/2, $size+$hw+$lw/2 );
    return $xo;
}

################ Draw Object ################

class DrawingObject;

field $gfx	:accessor :param;
field $size     :accessor :param;
field $txtfont  :accessor :param;
field $color    :accessor :param = "lime";
field $lw       :accessor :param = undef;
field $hw	:accessor :param = undef;

field $pdf	:accessor;
field $hhw      :accessor;
field $layout;

ADJUST {
    $pdf = $gfx->{' apipage'}->{' api'};
    $lw //= $size / 40;
    $hw //= $size / 4;
    $hhw = $hw/2;
};

method newxo() {
    $gfx = $pdf->xo_form;
    $gfx->fill_color($color);
    $gfx->stroke_color($color);
    $gfx->line_width($lw);
    $gfx;
}

# Drawing methods. Most of them return self for call chaining.
method move( $x, $y ) {
    $gfx->move( $x, $y );
    $self;
}
method line( $x, $y ) {
    $gfx->line( $x, $y );
    $self;
}
method vline( $y ) {
    $gfx->vline( $y );
    $self;
}
method hline( $x ) {
    $gfx->hline( $x );
    $self;
}
method close() {
    $gfx->close;
    $self;
}
method fill() {
    $gfx->fill;
    $self;
}
method fillstroke() {
    $gfx->fillstroke;
    $self;
}
method stroke() {
    $gfx->stroke;
    $self;
}
method rectangle( $x1,$y1, $x2,$y2 ) {
    $gfx->rectangle( $x1,$y1, $x2,$y2 );
    $self;
}
method bboxlw( $x1,$y1, $x2,$y2 ) {
    my $lw2 = $lw/2;
    $gfx->bbox( $x1-$lw2, $y1+$lw2, $x2+$lw2, $y2-$lw2 );
    $self;
}

#### High level methods.

method strum( $x, $y, $data, %args ) {

    my $tuplet = $args{tuplet} || 1;
    my $bpm    = $args{bpm}    || 4;
    $data = [ @$data ];

    while ( @$data ) {
	for my $beat ( 1 .. $bpm ) {
	    for my $tp ( 1 .. $tuplet ) {

		$_ = shift(@$data);
		my $arrow  = $_->{arrow}  || " ";
		my $mute   = $_->{mute}   || 0;
		my $accent = $_->{accent} || 0;
		my $arpeggio = $_->{arpeggio} || 0;

		# $args{x} = $x; $args{y} = $y; use DDP; p %args;

		$x += $hhw;

		if ( $arrow eq "u" ) {
		    $self->move( $x, $y );
		    if ( $arpeggio ) {
			#$self->gfx->line_dash_pattern(3);
			#$self->vline( $y+$size-$hhw )->stroke;
			#$self->gfx->line_dash_pattern();
			$self->vline(            $y +   $hhw );
			$self->curve( $x,        $y + 2*$hhw,
				      $x - $hhw, $y + 2*$hhw,
				      $x,        $y + 3*$hhw );
			$self->curve( $x + $hhw, $y + 4*$hhw,
				      $x,        $y + 4*$hhw,
				      $x,        $y + 5*$hhw );
			$self->vline(            $y+$size )->stroke;
		    }
		    else {
			$self->vline( $y + $size - $hhw );
		    }
		    $self->triangle( $x, $y + $size - $hhw, up => 1 );
		}
		elsif ( $arrow eq "d" ) {
		    $self->move( $x, $y + $hhw );
		    if ( $arpeggio ) {
			$self->vline(            $y + 3*$hhw );
			$self->curve( $x,        $y + 4*$hhw,
				      $x - $hhw, $y + 4*$hhw,
				      $x,        $y + 5*$hhw );
			$self->curve( $x + $hhw, $y + 6*$hhw,
				      $x,        $y + 6*$hhw,
				      $x,        $y + 7*$hhw );
			$self->vline(            $y+$size )->stroke;
		    }
		    else {
			$self->vline( $y+$size );
		    }
		    $self->triangle( $x, $y - $hw );
		}

		if ( $mute ) {
		    $self->move( $x - 0.8*$hhw, $y+$size + $hw )
		      ->line( $x + 0.8*$hhw, $y+$size + 0.2*$hw )->stroke;
		    $self->move( $x - 0.8*$hhw, $y+$size + 0.2*$hw )
		      ->line( $x + 0.8*$hhw, $y+$size + $hw )->stroke;
		}
		elsif ( $accent ) {
		    $self->move( $x - 0.8*$hhw, $y+$size + $hw )
		      ->line( $x + 0.8*$hhw, $y+$size + 0.6*$hw)
		      ->line( $x - 0.8*$hhw, $y+$size + 0.2*$hw )->stroke;
		}

		if ( $tp == 1 ) {
		    $self->set_txtfont($hw);
		    $self->cshow( $x, $y - $hhw/2, $beat );
		}
		else {
		    $self->set_txtfont($hw);
		    $self->cshow( $x, $y - $hhw/2, "&" );
		}
		if ( 0 and $tp < $tuplet ) {
		    my $dx = 2*$hw;
		    my $dy = $hw;
		    $self->move( $x, $y - $hhw - $hw )
		      ->vline( $y - 2*$hw )
		      ->hline( $x+$dx )
		      ->vline( $y - $hhw - $hw )
		      ->stroke;
		}
		$x += 3*$hhw;
	    }
	}
    }

    $x - $hw;
}

method triangle( $x, $y, %args ) {
    if ( $args{up} ) {
	$gfx->move( $x, $y-$hhw );
	$gfx->polyline( $x-0.8*$hhw,$y-$hhw, $x,$y+$hhw, $x+0.8*$hhw,$y-$hhw );
    }
    else {
	$gfx->move( $x, $hw );
	$gfx->polyline( $x-0.8*$hhw,$hw, $x,0, $x+0.8*$hhw,$hw );
    }
    $gfx->close->fillstroke;
    $self;
}

method curve( $cx1,$cy1, $cx2,$cy2, $x,$y ) {
    $gfx->curve($cx1,$cy1, $cx2,$cy2, $x,$y);
    $gfx;
}

# Text methods.
method set_txtfont( $sz = undef ) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_font_description($txtfont);
    $layout->set_font_size( $sz || $size );
}
method set_font_size($sz) {
    $layout->set_font_size($sz);
    $self;
}
method set_markup($t) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_markup("<span color='$color'>$t</span>");
#    $layout->set_markup($t);
    $self;
}
method get_size() {
    $layout->get_size;
}
method show( $x, $y, $markup = undef ) {
    $self->set_markup($markup) if defined $markup;
    $gfx->textstart;
    $layout->show( $x, $y, $gfx );
    $gfx->textend;
    $self;
}

method cshow( $x, $y, $markup = undef ) {
    $self->set_markup($markup) if defined $markup;
    my ( $w, $h ) = $layout->get_size;
    $gfx->textstart;
    $layout->show( $x - $w/2, $y, $gfx );
    $gfx->textend;
    $self;
}

1;
