#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5;

# Modern HTML5 output backend for ChordPro
# Uses Object::Pad with ChordProBase class

use v5.26;
use Object::Pad;
use utf8;
use Ref::Util qw(is_ref is_hashref);
use Text::Layout;
use Template;
use MIME::Base64 qw(encode_base64);
use Unicode::Collate;
use File::Basename qw(fileparse);
use File::Path qw(make_path);
use File::Spec;

use ChordPro::Paths;
use ChordPro::Files qw(fs_load fs_blob fs_open);
use ChordPro::Output::ChordProBase;
use ChordPro::Output::ChordDiagram::SVG;
use ChordPro::Output::HTML5Helper::FormatGenerator;
use ChordPro::Output::Common qw(prep_outlines fmt_subst);
use ChordPro::Utils qw(expand_tilde is_true);

class ChordPro::Output::HTML5
  :isa(ChordPro::Output::ChordProBase) {

    # SVG diagram generator
    field $svg_generator;
    
    # Template engine for CSS generation
    field $template_engine;

    BUILD {
        # Initialize SVG diagram generator with HTML escape function
        $svg_generator = ChordPro::Output::ChordDiagram::SVG->new(
            escape_fn => sub { $self->escape_text(@_) },
            config => $self->config,
        );
        
        # Initialize Template::Toolkit (following LaTeX.pm pattern)
        my $config = $self->config;
        
        # Unlock config to access (following PDF.pm pattern)
        $config->unlock;
        my $html5_cfg = $config->{html5};
        
        # Use findresdirs to get all template directories  
        # Make a copy of the array to avoid modifying config directly
        my $include_path = [ @{$html5_cfg->{template_include_path} // []} ];
        push( @$include_path, @{CP->findresdirs( "templates" )} );
        
        $config->lock;
        
        $template_engine = Template->new({
            INCLUDE_PATH => $include_path,
            INTERPOLATE => 1,
        }) || die "$Template::ERROR\n";
    }

    # =================================================================
    # TEMPLATE PROCESSING HELPER
    # =================================================================

    method _process_template($template_name, $vars) {
        my $output = '';
        my $config = $self->config;
        
        $config->unlock;
        my $html5_cfg = $config->{html5};
        
        # Handle paged template names
        my $template;
        if ($template_name =~ /^paged_(.+)$/) {
            my $base_name = $1;
            # Try paged template first, fall back to regular
            my $paged_cfg = eval { $html5_cfg->{paged} } // {};
            $template = eval { $paged_cfg->{templates}->{$base_name} }
                     // eval { $html5_cfg->{templates}->{$base_name} };
        } else {
            $template = eval { $html5_cfg->{templates}->{$template_name} };
        }
        
        $config->lock;
        
        unless (defined $template) {
            die "Template '$template_name' not found in config";
        }
        
        $template_engine->process($template, $vars, \$output)
            || die "Template error ($template_name): " . $template_engine->error();
        
        return $output;
    }

    # =================================================================
    # TEMPLATE-BASED ELEMENT RENDERERS (LaTeX.pm pattern)
    # =================================================================

    method _chord_display_and_class($chord) {
        my $chord_name = '';
        my $is_annotation = 0;

        if ($chord) {
            if (ref($chord) eq 'HASH') {
                $chord_name = $chord->{name} // '';
            } else {
                if (ref($chord) && $chord->can('info')) {
                    my $info = $chord->info;
                    $is_annotation = $info
                      && $info->can('is_annotation')
                      && $info->is_annotation;
                }

                if (ref($chord) && $chord->can('chord_display')) {
                    $chord_name = $chord->chord_display // '';
                } elsif (ref($chord) && $chord->can('name')) {
                    $chord_name = $chord->name // '';
                } else {
                    $chord_name = "$chord";
                }
            }
        }

        my $chord_class = $is_annotation ? 'cp-annotation' : 'cp-chord';

        return ($chord_name, $chord_class, $is_annotation);
    }

    method _render_songline_template($element) {
        my $config = $self->config // {};
        my $inline_cfg = eval { $config->{settings}->{'inline-chords'} };
        my $inline_enabled = is_true($inline_cfg);

        if ($inline_enabled && !$self->is_lyrics_only()) {
            my $inline_format = $inline_cfg;
            if (!defined($inline_format) || $inline_format =~ /^(?:1|true|yes)\z/i) {
                $inline_format = '[%s]';
            }
            $inline_format = '[%s]' if $inline_format !~ /%s/;

            my $inline_annotations = eval { $config->{settings}->{'inline-annotations'} } // '%s';
            $inline_annotations = '%s' if $inline_annotations !~ /%s/;

            my $chords = $element->{chords} // [];
            my $phrases = $element->{phrases} // [];
            my $html = qq{<div class="cp-songline cp-inline-chords">\n};

            for (my $i = 0; $i < @$phrases; $i++) {
                my $chord = $chords->[$i];
                my ($chord_name, undef, $is_annotation) = $self->_chord_display_and_class($chord);

                if ($chord_name ne '') {
                    my $format = $is_annotation ? $inline_annotations : $inline_format;
                    my $formatted = $format;
                    $formatted =~ s/%s/$chord_name/g;
                    my $display = $self->process_text_with_markup($formatted);
                    my $class = $is_annotation ? 'cp-inline-annotation' : 'cp-inline-chord';
                    $html .= qq{  <span class="$class">$display</span>};
                }

                my $lyrics = $phrases->[$i] // '';
                if ($lyrics ne '') {
                    my $processed = $self->process_text_with_markup($lyrics);
                    $html .= qq{  <span class="cp-lyrics">$processed</span>};
                }
            }

            $html .= qq{\n</div>\n};
            return $html;
        }

        # Prepare chord-lyric pairs
        my @pairs;
        my $chords = $element->{chords} // [];
        my $phrases = $element->{phrases} // [];
        my $has_chords = 0;
        
        for (my $i = 0; $i < @$phrases; $i++) {
            my $chord = $chords->[$i];
            my ($chord_name, $chord_class) = $self->_chord_display_and_class($chord);
            
            my $lyrics = $phrases->[$i] // '';
            my $is_chord_only = ($chord_name ne '' && $lyrics eq '');
            $has_chords = 1 if $chord_name ne '';
            
            push @pairs, {
                chord => $chord_name,
                chord_class => $chord_class,
                lyrics => $self->process_text_with_markup($lyrics),
                is_chord_only => $is_chord_only,
            };
        }

        my $lyrics_text = join('', map { $_->{lyrics} } @pairs);
        
        return $self->_process_template('songline', {
            pairs => \@pairs,
            has_chords => $has_chords,
            lyrics_text => $lyrics_text,
        });
    }

    method _render_comment_template($element) {
        return $self->_process_template('comment', {
            text => $self->process_text_with_markup($element->{text} // ''),
            italic => ($element->{type} eq 'comment_italic'),
        });
    }

    method _render_image_template($element) {
        my $opts = $element->{opts} // {};
        my $align = $opts->{align} // '';
        $align = lc($align) if defined $align;

        my @container_classes = ('cp-image-container');
        if ($align =~ /^(center|left|right)$/) {
            push @container_classes, "cp-image-align-$align";
        }
        push @container_classes, 'cp-image-spread' if is_true($opts->{spread});

        my $img_class = $opts->{class} // 'cp-image';
        if ($img_class !~ /\bcp-image\b/) {
            $img_class = "cp-image $img_class";
        }

        my $width = $opts->{width};
        my $height = $opts->{height};
        my %style;

        my ($scale_x, $scale_y);
        if (ref($opts->{scale}) eq 'ARRAY') {
            $scale_x = $opts->{scale}->[0];
            $scale_y = $opts->{scale}->[1] // $scale_x;
        } elsif (defined $opts->{scale} && $opts->{scale} ne '') {
            $scale_x = $opts->{scale};
            $scale_y = $opts->{scale};
        }

        my $parse_scale = sub {
            my ($value) = @_;
            return undef unless defined $value && $value ne '';
            if ($value =~ /^(\d+(?:\.\d+)?)%$/) {
                return { type => 'percent', value => $1 };
            }
            return { type => 'factor', value => $value + 0 };
        };

        my $scale_x_info = $parse_scale->($scale_x);
        my $scale_y_info = $parse_scale->($scale_y);

        my $format_percent = sub {
            my ($value) = @_;
            my $pct = sprintf('%.2f', $value * 100);
            $pct =~ s/\.0+$//;
            $pct =~ s/\.$//;
            return $pct . '%';
        };

        if ($scale_x_info) {
            if ($scale_x_info->{type} eq 'percent') {
                $style{width} = $scale_x_info->{value} . '%';
                if ($scale_y_info && $scale_y_info->{type} eq 'percent'
                    && $scale_y_info->{value} != $scale_x_info->{value}) {
                    $style{height} = $scale_y_info->{value} . '%';
                }
                $width = undef;
                $height = undef;
            } else {
                my $has_dimensions = defined $width || defined $height;
                if ($has_dimensions) {
                    my $scale_dim = sub {
                        my ($value, $scale) = @_;
                        return $value unless defined $value && defined $scale;
                        if ($value =~ /^(\d+(?:\.\d+)?)(%)?$/) {
                            my $num = $1 * $scale;
                            return defined($2) ? $num . '%' : $num;
                        }
                        return $value;
                    };

                    my $scale_y_value = $scale_y_info ? $scale_y_info->{value} : $scale_x_info->{value};
                    $width = $scale_dim->($width, $scale_x_info->{value}) if defined $width;
                    $height = $scale_dim->($height, $scale_y_value) if defined $height;
                } else {
                    $style{width} = $format_percent->($scale_x_info->{value});
                    if ($scale_y_info && $scale_y_info->{type} eq 'factor'
                        && $scale_y_info->{value} != $scale_x_info->{value}) {
                        $style{height} = $format_percent->($scale_y_info->{value});
                    }
                }
            }
        }

        my $width_attr = $width;
        my $height_attr = $height;
        if (defined $width && $width =~ /%$/) {
            $style{width} = $width;
            $width_attr = '';
        }
        if (defined $height && $height =~ /%$/) {
            $style{height} = $height;
            $height_attr = '';
        }

        my $style_str = '';
        if (%style) {
            $style_str = join('; ', map { $_ . ': ' . $style{$_} } sort keys %style);
        }

        return $self->_process_template('image', {
            uri => $element->{uri} // '',
            title => $element->{title} // '',
            width => $width_attr // '',
            height => $height_attr // '',
            class => $img_class,
            container_class => join(' ', @container_classes),
            style => $style_str,
        });
    }

    method render_gridline($element) {
        my $tokens = $element->{tokens} // [];
        my $margin = $element->{margin};
        my $comment = $element->{comment};

        my $display_chord = sub {
            my ($chord) = @_;
            my $text = '';

            if (ref($chord) eq 'HASH') {
                $text = $chord->{name} // '';
            } elsif ($chord && $chord->can('chord_display')) {
                $text = $chord->chord_display;
            } elsif ($chord && $chord->can('name')) {
                $text = $chord->name;
            } else {
                $text = "$chord";
            }

            return $text;
        };

        my $html = '<div class="cp-gridline">';
        
        # Render margin if present
        if ($margin) {
            my $margin_text = $margin->{chord} // $margin->{text} // '';
            if (ref($margin_text) && $margin_text->can('chord_display')) {
                $margin_text = $margin_text->chord_display;
            } elsif (ref($margin_text) && $margin_text->can('name')) {
                $margin_text = $margin_text->name;
            }
            $html .= '<span class="cp-grid-margin">' . $self->escape_text($margin_text) . '</span>';
        }
        
        # Render tokens
        $html .= '<span class="cp-grid-tokens">';
        foreach my $token (@$tokens) {
            my $class = $token->{class} // '';
            my $text = '';
            my @classes;
            my $data_attrs = '';
            
            if ($class eq 'chord') {
                $text = $display_chord->($token->{chord});
                push @classes, 'cp-grid-chord';
            } elsif ($class eq 'chords') {
                my $chords = $token->{chords} // [];
                my @parts;
                for my $chord (@$chords) {
                    if (!defined $chord) {
                        push @parts, '';
                    } elsif ($chord eq '/' || $chord eq '.') {
                        push @parts, $chord;
                    } else {
                        push @parts, $display_chord->($chord);
                    }
                }
                $text = join('~', @parts);
                push @classes, 'cp-grid-chord';
            } else {
                $text = $token->{symbol} // '';
                push @classes, 'cp-grid-symbol';

                if ($class eq 'bar') {
                    push @classes, 'cp-grid-bar';
                    my $symbol = $token->{symbol} // '';
                    if ($symbol eq '||') {
                        push @classes, 'cp-grid-bar-double';
                    } elsif ($symbol eq '|.') {
                        push @classes, 'cp-grid-bar-end';
                    } elsif ($symbol eq '|:' || $symbol eq '{') {
                        push @classes, 'cp-grid-bar-repeat-start';
                    } elsif ($symbol eq ':|' || $symbol eq '}') {
                        push @classes, 'cp-grid-bar-repeat-end';
                    } elsif ($symbol eq ':|:' || $symbol eq '}{') {
                        push @classes, 'cp-grid-bar-repeat-both';
                    } else {
                        push @classes, 'cp-grid-bar-single';
                    }

                    if (defined $token->{volta}) {
                        push @classes, 'cp-grid-volta';
                        $data_attrs = qq{ data-volta="$token->{volta}"};
                    }
                } elsif ($class eq 'repeat1') {
                    push @classes, 'cp-grid-repeat', 'cp-grid-repeat1';
                } elsif ($class eq 'repeat2') {
                    push @classes, 'cp-grid-repeat', 'cp-grid-repeat2';
                } elsif ($class eq 'slash') {
                    push @classes, 'cp-grid-slash';
                } elsif ($class eq 'space') {
                    push @classes, 'cp-grid-space';
                }
            }

            if ($class && !grep { $_ eq "cp-grid-$class" } @classes) {
                push @classes, "cp-grid-$class";
            }

            my $class_attr = @classes ? join(' ', @classes) : '';
            my $class_str = $class_attr ? qq{ class="$class_attr"} : '';
            $html .= '<span' . $class_str . $data_attrs . '>' . $self->escape_text($text) . '</span>';
        }
        $html .= '</span>';
        
        # Render comment if present
        if ($comment) {
            my $comment_text = $comment->{chord} // $comment->{text} // '';
            if (ref($comment_text) && $comment_text->can('chord_display')) {
                $comment_text = $comment_text->chord_display;
            } elsif (ref($comment_text) && $comment_text->can('name')) {
                $comment_text = $comment_text->name;
            }
            $html .= '<span class="cp-grid-comment">' . $self->escape_text($comment_text) . '</span>';
        }
        
        $html .= '</div>';
        return $html;
    }

    method _process_song_body($body, $song = undef) {
        my $html = '';

        foreach my $element (@{$body}) {
            my $type = $element->{type};

            # Dispatch to appropriate handler
            if ($type eq 'songline') {
                $html .= $self->_render_songline_template($element);
            }
            elsif ($type eq 'comment' || $type eq 'comment_italic') {
                $html .= $self->_render_comment_template($element);
            }
            elsif ($type eq 'image') {
                my $delegate_asset;
                if ( ($element->{subtype} // '') eq 'delegate' ) {
                    $delegate_asset = $element;
                } elsif ($song && $element->{id}) {
                    my $asset = $song->{assets}->{$element->{id}};
                    if ($asset && ($asset->{subtype} // '') eq 'delegate') {
                        $delegate_asset = $asset;
                    }
                }

                if ($delegate_asset) {
                    $html .= $self->_render_delegate_element($delegate_asset, $song);
                } else {
                    # Resolve image URI from asset if not in element (Bug 2/3 fix)
                    my $img_element = $element;
                    if (!$element->{uri} && $song && $element->{id}) {
                        my $asset = $song->{assets}->{$element->{id}};
                        if ($asset && $asset->{uri}) {
                            $img_element = { %$element, uri => $asset->{uri} };
                        }
                    }
                    # Convert file URIs to base64 data URIs for portability
                    if ($img_element->{uri} && $img_element->{uri} !~ /^data:/) {
                        $img_element = $self->_resolve_image_to_data_uri($img_element);
                    }
                    $html .= $self->_render_image_template($img_element);
                }
            }
            elsif ($type eq 'empty') {
                $html .= qq{<div class="cp-empty"></div>\n};
            }
            elsif ($type eq 'chorus') {
                my $body = $element->{body} // [];
                my $label = $element->{label};
                if ((!defined $label || $label eq '') && @$body) {
                    my $maybe_label = $body->[0];
                    if (($maybe_label->{type} // '') eq 'set' && ($maybe_label->{name} // '') eq 'label') {
                        $label = $maybe_label->{value};
                        $body = [ @{$body}[1 .. $#$body] ] if $#$body >= 1;
                        $body = [] if $#$body < 1;
                    }
                }
                my $label_attr = '';
                if (defined $label && $label ne '') {
                    my $escaped = $self->escape_text($label);
                    $label_attr = qq{ data-label="$escaped"};
                }
                $html .= qq{<div class="cp-chorus"$label_attr>\n};
                $html .= $self->_process_song_body($body, $song);
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'rechorus') {
                $html .= $self->handle_rechorus($element);
            }
            elsif ($type eq 'verse') {
                my $body = $element->{body} // [];
                my $label = $element->{label};
                if ((!defined $label || $label eq '') && @$body) {
                    my $maybe_label = $body->[0];
                    if (($maybe_label->{type} // '') eq 'set' && ($maybe_label->{name} // '') eq 'label') {
                        $label = $maybe_label->{value};
                        $body = [ @{$body}[1 .. $#$body] ] if $#$body >= 1;
                        $body = [] if $#$body < 1;
                    }
                }
                my $label_attr = '';
                if (defined $label && $label ne '') {
                    my $escaped = $self->escape_text($label);
                    $label_attr = qq{ data-label="$escaped"};
                }
                $html .= qq{<div class="cp-verse"$label_attr>\n};
                $html .= $self->_process_song_body($body, $song);
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'bridge') {
                my $body = $element->{body} // [];
                my $label = $element->{label};
                if ((!defined $label || $label eq '') && @$body) {
                    my $maybe_label = $body->[0];
                    if (($maybe_label->{type} // '') eq 'set' && ($maybe_label->{name} // '') eq 'label') {
                        $label = $maybe_label->{value};
                        $body = [ @{$body}[1 .. $#$body] ] if $#$body >= 1;
                        $body = [] if $#$body < 1;
                    }
                }
                my $label_attr = '';
                if (defined $label && $label ne '') {
                    my $escaped = $self->escape_text($label);
                    $label_attr = qq{ data-label="$escaped"};
                }
                $html .= qq{<div class="cp-bridge"$label_attr>\n};
                $html .= $self->_process_song_body($body, $song);
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'tab') {
                my $body = $element->{body} // [];
                my $label = $element->{label};
                if ((!defined $label || $label eq '') && @$body) {
                    my $maybe_label = $body->[0];
                    if (($maybe_label->{type} // '') eq 'set' && ($maybe_label->{name} // '') eq 'label') {
                        $label = $maybe_label->{value};
                        $body = [ @{$body}[1 .. $#$body] ] if $#$body >= 1;
                        $body = [] if $#$body < 1;
                    }
                }
                my $label_attr = '';
                if (defined $label && $label ne '') {
                    my $escaped = $self->escape_text($label);
                    $label_attr = qq{ data-label="$escaped"};
                }
                $html .= qq{<div class="cp-tab"$label_attr>\n};
                $html .= $self->_process_song_body($body, $song);
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'tabline') {
                my $text = $self->escape_text($element->{text} // '');
                $html .= qq{<div class="cp-tabline">$text</div>\n};
            }
            elsif ($type eq 'grid') {
                my $body = $element->{body} // [];
                my $label = $element->{label};
                if ((!defined $label || $label eq '') && @$body) {
                    my $maybe_label = $body->[0];
                    if (($maybe_label->{type} // '') eq 'set' && ($maybe_label->{name} // '') eq 'label') {
                        $label = $maybe_label->{value};
                        $body = [ @{$body}[1 .. $#$body] ] if $#$body >= 1;
                        $body = [] if $#$body < 1;
                    }
                }
                my $label_attr = '';
                if (defined $label && $label ne '') {
                    my $escaped = $self->escape_text($label);
                    $label_attr = qq{ data-label="$escaped"};
                }
                $html .= qq{<div class="cp-grid"$label_attr>\n};
                $html .= $self->_process_song_body($body, $song);
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'gridline') {
                $html .= $self->render_gridline($element);
            }
            elsif ($type eq 'comment_box') {
                $html .= $self->render_section_begin('comment_box');
                $html .= $self->render_text($element->{text} // '');
                $html .= $self->render_section_end('comment_box');
            }
            elsif ($type eq 'new_page' || $type eq 'newpage') {
                my $break_class = $self->_newpage_break_class();
                $html .= qq{<div class="cp-new-page$break_class"></div>\n};
            }
            elsif ($type eq 'new_physical_page') {
                my $break_class = $self->_newpage_break_class();
                $html .= qq{<div class="cp-new-physical-page$break_class"></div>\n};
            }
            elsif ($type eq 'colb' || $type eq 'column_break') {
                $html .= qq{<div class="cp-column-break"></div>\n};
            }
            elsif ($element->{body}) {
                $html .= $self->_process_song_body($element->{body}, $song);
            }
            # Ignore other types (set, control, etc.)
        }

        return $html;
    }

    method _resolve_image_to_data_uri($element) {
        my $uri = $element->{uri} // '';
        return $element unless $uri && $uri !~ /^(?:data:|https?:)/;

        # Try to read the file and convert to base64 data URI
        my $path = $uri;
        if (-f $path) {
            my %mime_types = (
                png  => 'image/png',
                jpg  => 'image/jpeg',
                jpeg => 'image/jpeg',
                gif  => 'image/gif',
                svg  => 'image/svg+xml',
                webp => 'image/webp',
                bmp  => 'image/bmp',
            );

            my $ext = '';
            $ext = lc($1) if $path =~ /\.(\w+)$/;
            my $mime = $mime_types{$ext};

            if ($mime) {
                open my $fh, '<:raw', $path;
                if ($fh) {
                    local $/;
                    my $data = <$fh>;
                    close $fh;
                    if (defined $data && length($data) > 0) {
                        my $b64 = encode_base64($data, '');
                        my $data_uri = "data:$mime;base64,$b64";
                        return { %$element, uri => $data_uri };
                    }
                }
            }
        }

        # Fall back to original URI if embedding fails
        return $element;
    }

    method _render_delegate_element($element, $song = undef) {
        my $delegate = $element->{delegate} // '';
        my $handler = $element->{handler} // '';
        return '' unless $delegate && $handler;

        my $pkg = __PACKAGE__;
        $pkg =~ s/::Output::[:\w]+$/::Delegate::$delegate/;
        eval "require $pkg";
        if ($@) {
            warn("HTML5: Failed to load delegate $delegate: $@\n");
            return '';
        }

        my $hd = $pkg->can($handler);
        unless ($hd) {
            warn("HTML5: Missing delegate handler ${pkg}::$handler\n");
            return '';
        }

        my $elt = { %$element };
        if (!$elt->{data} && $elt->{uri}) {
            my $loaded = fs_load($elt->{uri});
            $elt->{data} = $loaded if $loaded;
        }

        my $res = $hd->( $song, elt => $elt, pagewidth => undef );
        return '' unless $res;

        if (ref($res) eq 'ARRAY') {
            return join('', map { $self->_render_delegate_result($_) } @$res);
        }

        return $self->_render_delegate_result($res);
    }

    method _render_delegate_result($res) {
        return '' unless ref($res) eq 'HASH';
        return '' unless ($res->{type} // '') eq 'image';

        my $subtype = $res->{subtype} // '';
        if ($subtype eq 'svg') {
            my $svg = '';
            if ($res->{data}) {
                if (ref($res->{data}) eq 'ARRAY') {
                    $svg = join("\n", @{$res->{data}});
                } else {
                    $svg = $res->{data};
                }
            } elsif ($res->{uri}) {
                my $lines = fs_load($res->{uri});
                if ($lines && ref($lines) eq 'ARRAY') {
                    $svg = join("\n", @$lines);
                } elsif (defined $lines) {
                    $svg = $lines;
                }
            }

            return '' unless $svg ne '';
            return qq{<div class="cp-delegate cp-delegate-svg">\n$svg\n</div>\n};
        }

        my $opts = { %{ $res->{opts} // {} }, class => 'cp-delegate' };
        if ($res->{uri}) {
            # Convert file URI to data URI for portability (Bug 4 fix)
            my $resolved = $self->_resolve_image_to_data_uri({ uri => $res->{uri} });
            return $self->render_image($resolved->{uri}, $opts);
        }

        if (defined $res->{data}) {
            my %mime = (
                png  => 'image/png',
                jpg  => 'image/jpeg',
                jpeg => 'image/jpeg',
                gif  => 'image/gif',
            );
            my $mime_type = $mime{lc($subtype)} // '';
            if ($mime_type) {
                my $data = $res->{data};
                $data = encode_base64($data, '');
                my $uri = "data:$mime_type;base64,$data";
                return $self->render_image($uri, $opts);
            }
        }

        return '';
    }

    method handle_rechorus($elt) {
        my $config = $self->config // {};
        my $recall = eval { $config->{html5}->{chorus}->{recall} }
          // eval { $config->{pdf}->{chorus}->{recall} }
          // eval { $config->{text}->{chorus}->{recall} }
          // {};

        my $quote = eval { $recall->{quote} } // 0;
        my $tag = eval { $recall->{tag} };
        $tag = 'Chorus' if !defined($tag) || $tag eq '';
        my $type = eval { $recall->{type} } // '';
        my $choruslike = eval { $recall->{choruslike} } // 0;

        if ( $quote && $elt->{chorus} ) {
            return $self->handle_chorus({ body => $elt->{chorus} });
        }

        my $output = '';
        if ( $type && $tag ne '' ) {
            if ( $type eq 'comment' || $type eq 'comment_italic' ) {
                $output = $self->_render_comment_template({
                    text => $tag,
                    type => $type,
                });
            }
            elsif ( $type eq 'comment_box' ) {
                $output = $self->render_section_begin('comment_box')
                  . $self->render_text($tag)
                  . $self->render_section_end('comment_box');
            }
        }

        if ( $output eq '' ) {
            $output = $self->render_section_begin('rechorus')
              . $self->render_text($tag)
              . $self->render_section_end('rechorus');
        }

        if ( $choruslike ) {
            return $self->render_section_begin('choruslike')
              . $output
              . $self->render_section_end('choruslike');
        }

        return $output;
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Document Structure
    # =================================================================

    method render_document_begin($metadata) {
        my $title = $self->escape_text($metadata->{title} // 'ChordPro Songbook');

        return qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="ChordPro HTML5 Backend">
    <title>$title</title>
    <style>
} . $self->generate_default_css() . qq{
    </style>
</head>
<body class="chordpro-songbook">
};
    }

    method render_document_end() {
        return qq{</body>
</html>
};
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Text Rendering
    # =================================================================

    method render_text($text, $style=undef) {
        my $processed = $self->process_text_with_markup($text);

        return $processed unless $style;

        return qq{<span class="cp-$style">$processed</span>};
    }

    method render_line_break() {
        return "<br>\n";
    }

    method render_paragraph_break() {
        return "\n";
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Structural Elements
    # =================================================================

    method render_section_begin($type, $label=undef) {
        my $label_attr = '';
        if (defined $label && $label ne '') {
            my $escaped_label = $self->escape_text($label);
            $label_attr = qq{ data-label="$escaped_label"};
        }

        return qq{<div class="cp-$type"$label_attr>\n};
    }

    method render_section_end($type) {
        return qq{</div><!-- .cp-$type -->\n};
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Media
    # =================================================================

    method render_image($uri, $opts={}) {
        my $escaped_uri = $self->escape_text($uri);
        my $alt = $self->escape_text($opts->{alt} // '');

        my ($scale_x, $scale_y);
        if (ref($opts->{scale}) eq 'ARRAY') {
            $scale_x = $opts->{scale}->[0];
            $scale_y = $opts->{scale}->[1] // $scale_x;
        } elsif (defined $opts->{scale} && $opts->{scale} ne '') {
            $scale_x = $opts->{scale};
            $scale_y = $opts->{scale};
        }

        my %style;
        if (defined $scale_x) {
            my $pct = sprintf('%.2f', $scale_x * 100);
            $pct =~ s/\.0+$//;
            $pct =~ s/\.$//;
            $style{width} = $pct . '%';
            if (defined $scale_y && $scale_y != $scale_x) {
                my $pct_y = sprintf('%.2f', $scale_y * 100);
                $pct_y =~ s/\.0+$//;
                $pct_y =~ s/\.$//;
                $style{height} = $pct_y . '%';
            }
        }

        my @attrs;
        push @attrs, qq{src="$escaped_uri"};
        push @attrs, qq{alt="$alt"};
        push @attrs, qq{width="$opts->{width}"} if $opts->{width} && !defined $scale_x;
        push @attrs, qq{height="$opts->{height}"} if $opts->{height} && !defined $scale_x;
        push @attrs, qq{class="$opts->{class}"} if $opts->{class};
        if (%style) {
            my $style_str = join('; ', map { $_ . ': ' . $style{$_} } sort keys %style);
            push @attrs, qq{style="$style_str"};
        }

        my $attrs_str = join(' ', @attrs);
        return qq{<img $attrs_str>\n};
    }

    method render_metadata($key, $value) {
        my $escaped_key = $self->escape_text($key);
        my $escaped_value = $self->escape_text($value);

        return qq{<meta name="chordpro:$escaped_key" content="$escaped_value">\n};
    }

    # =================================================================
    # REQUIRED CHORDPRO METHODS - Music Notation
    # =================================================================

    method render_chord($chord_obj) {
        my ($chord_name, $chord_class) = $self->_chord_display_and_class($chord_obj);
        my $display = $self->process_text_with_markup($chord_name);
        return qq{<span class="$chord_class">$display</span>};
    }

    method render_songline($phrases, $chords) {
        my $html = qq{<div class="cp-songline">\n};

        # Check if lyrics-only mode
        if ($self->is_lyrics_only()) {
            my $text = join('', @$phrases);
            $html .= qq{  <span class="cp-lyrics">} . $self->escape_text($text) . qq{</span>\n};
            $html .= qq{</div>\n};
            return $html;
        }

        # Check if line has any real chords
        my $has_chords = 0;
        if ($chords) {
            foreach my $chord (@$chords) {
                next unless $chord && is_ref($chord);
                my ($chord_name) = $self->_chord_display_and_class($chord);
                if ($chord_name ne '') {
                    $has_chords = 1;
                    last;
                }
            }
        }

        # If no chords in this line, render as simple lyrics (no chord spacing)
        # This applies in single-space mode OR when line genuinely has no chords
        if (!$has_chords) {
            my $text = join('', @$phrases);
            $html .= qq{  <span class="cp-lyrics">} . $self->process_text_with_markup($text) . qq{</span>\n};
            $html .= qq{</div>\n};
            return $html;
        }

        # Render chord-lyric pairs
        for (my $i = 0; $i < @$phrases; $i++) {
            my $phrase = $phrases->[$i] // '';
            my $chord = $chords->[$i];
            my ($chord_name, $chord_class) = $self->_chord_display_and_class($chord);
            
            # Check if this is a chord-only pair (chord with empty lyrics)
            my $is_chord_only = ($chord_name ne '' && $phrase eq '');
            my $pair_class = $is_chord_only ? 'cp-chord-lyric-pair cp-chord-only' : 'cp-chord-lyric-pair';

            $html .= qq{  <span class="$pair_class">\n};

            # Chord span (empty if no chord)
            if ($chord_name ne '') {
                my $display = $self->process_text_with_markup($chord_name);
                $html .= qq{    <span class="$chord_class">$display</span>\n};
            } else {
                $html .= qq{    <span class="cp-chord cp-chord-empty"></span>\n};
            }

            # Lyric span
            my $processed_phrase = $self->process_text_with_markup($phrase);
            $html .= qq{    <span class="cp-lyrics">$processed_phrase</span>\n};

            $html .= qq{  </span>\n};
        }

        $html .= qq{</div>\n};
        return $html;
    }

    method render_grid_line($tokens) {
        my $html = qq{<div class="cp-gridline">\n};

        foreach my $token (@$tokens) {
            if ($token->{class} eq 'chord') {
                my $chord_name = $self->process_text_with_markup($token->{chord}->key);
                $html .= qq{  <span class="cp-grid-chord">$chord_name</span>\n};
            } else {
                my $symbol = $self->process_text_with_markup($token->{symbol});
                $html .= qq{  <span class="cp-grid-symbol">$symbol</span>\n};
            }
        }

        $html .= qq{</div>\n};
        return $html;
    }

    # =================================================================
    # SONG GENERATION - Override to customize structure
    # =================================================================

    method generate_song($song, $paged_mode = 0, $song_id = undef, $page_break_class_override = undef) {
        # Structurize the song to convert start_of/end_of directives into containers
        eval { $song->structurize } if $song->can('structurize');

        # Process metadata with markup
        my $meta = $song->{meta} // {};
        my $processed_meta = {};
        foreach my $key (keys %$meta) {
            if (ref($meta->{$key}) eq 'ARRAY') {
                $processed_meta->{$key} = [
                    map { $self->process_text_with_markup($_) } @{$meta->{$key}}
                ];
            }
        }

        # Process song body to HTML
        my $body_html = '';
        if ($song->{body}) {
            $body_html = $self->_process_song_body($song->{body}, $song);
        }

        # Generate chord diagrams if present (unless lyrics-only)
        my $chord_diagrams_html = '';
        unless ($self->is_lyrics_only()) {
            $chord_diagrams_html = $self->render_chord_diagrams($song);
        }

        # Diagram placement and alignment (HTML5 overrides PDF)
        my $diagrams_position = '';
        my $diagrams_align = '';
        if ($chord_diagrams_html ne '') {
            my $config = $self->config // {};
            my $html5_diagrams = eval { $config->{html5}->{diagrams} } // {};
            my $pdf_diagrams = eval { $config->{pdf}->{diagrams} } // {};

            $diagrams_position = lc( eval { $html5_diagrams->{show} }
                // eval { $pdf_diagrams->{show} }
                // 'bottom' );
            $diagrams_align = lc( eval { $html5_diagrams->{align} }
                // eval { $pdf_diagrams->{align} }
                // 'left' );

            $diagrams_position = 'bottom'
                unless $diagrams_position =~ /^(?:top|bottom|right|below)\z/;
            $diagrams_align = 'left'
                unless $diagrams_align =~ /^(?:left|right|center|spread)\z/;
        }

        # Process title/subtitles with markup
        my $processed_title = $song->{title} ? $self->process_text_with_markup($song->{title}) : '';
        my @processed_subtitles = ();
        if ($song->{subtitle}) {
            @processed_subtitles = map { $self->process_text_with_markup($_) } @{$song->{subtitle}};
        }

        # Prepare data attributes for paged mode (metadata without markup for CSS string-set)
        my $data_attrs = {};
        if ($paged_mode) {
            my $join_meta = sub {
                my ($field, $fallback) = @_;
                my $val = $meta->{$field};
                if ($val && ref($val) eq 'ARRAY' && @$val) {
                    return join(", ", @$val);
                }
                if (defined $fallback) {
                    if (ref($fallback) eq 'ARRAY') {
                        return join(", ", @$fallback);
                    }
                    return $fallback;
                }
                return undef;
            };

            my %fields = (
                title => $song->{title},
                subtitle => $song->{subtitle},
                artist => undef,
                album => undef,
                composer => undef,
                lyricist => undef,
                copyright => undef,
                year => undef,
                key => undef,
                capo => undef,
                duration => undef,
            );

            for my $field (sort keys %fields) {
                my $value = $join_meta->($field, $fields{$field});
                if (defined $value && $value ne '') {
                    $data_attrs->{"data_$field"} = $value;
                }
            }
        }

        my $page_break_class = '';
        if ($paged_mode) {
            if (defined $page_break_class_override) {
                $page_break_class = $page_break_class_override;
            } else {
                my $config = $self->config // {};
                my $break_setting = eval { $config->{html5}->{paged}->{song}->{'page-break'} } // 'none';
                my $classes = $self->_break_classes_for_setting($break_setting, 'none');
                $page_break_class = join(' ', @$classes) if @$classes;
            }
        }

        # Prepare template variables
        my $vars = {
            title => $processed_title,
            subtitle => \@processed_subtitles,
            meta => $processed_meta,
            chord_diagrams_html => $chord_diagrams_html,
            diagrams_position => $diagrams_position,
            diagrams_align => $diagrams_align,
            body_html => $body_html,
            paged_mode => $paged_mode,
            song_id => $song_id,
            page_break_class => $page_break_class,
            %$data_attrs,  # Merge data attributes
        };

        # Process song template (use paged template if in paged mode)
        my $template_name = $paged_mode ? 'paged_song' : 'song';
        return $self->_process_template($template_name, $vars);
    }

    method _generate_toc($songs, $paged_mode = 0) {
        return '' unless $paged_mode;

        my $options = $self->options // {};
        return '' unless ($options->{toc} // (@$songs > 1));

        my $config = $self->config // {};
        my $contents = eval { $config->{contents} } // [];
        return '' unless ref($contents) eq 'ARRAY' && @$contents;

        my @toc_sections;

        for my $ctl (@$contents) {
            next if eval { $ctl->{omit} };

            my $fields = eval { $ctl->{fields} } // [];
            my $label = eval { $ctl->{label} } // 'Table of Contents';
            my $line_tpl = eval { $ctl->{line} } // '%{title}';
            my $page_tpl = eval { $ctl->{pageno} } // '%{page}';
            my $break_tpl = eval { $ctl->{break} };
            my $name = eval { $ctl->{name} } // 'toc';
            my $line_has_page = ($line_tpl // '') =~ /%\{page(?:\b|[^}]*)\}/;

            my $book = prep_outlines($songs, {
                fields => $fields,
                omit => 0,
            });
            next unless $book && @$book;

            my @entries;
            my $prev_break = '';

            for my $item (@$book) {
                my $song = $item->[-1];
                my $song_id = eval { $song->{meta}->{html5_id}->[0] } // '';
                next unless $song_id;

                if (defined $break_tpl) {
                    my $break_text = fmt_subst($song, $break_tpl);
                    my $normalized = $break_text;
                    $normalized =~ s/^(\n|\r|\n\r|\r\n)+//g;
                    if ($normalized ne $prev_break) {
                        push @entries, {
                            type => 'break',
                            text => $normalized,
                        } if $normalized ne '';
                        $prev_break = $normalized;
                    }
                }

                my $title = fmt_subst($song, $line_tpl);
                my $page_text = fmt_subst($song, $page_tpl);

                push @entries, {
                    type => 'entry',
                    text => $title,
                    page_text => $page_text,
                    page_ref => '#' . $song_id,
                    page_in_line => $line_has_page ? 1 : 0,
                };
            }

            next unless @entries;

            push @toc_sections, $self->_process_template('paged_toc', {
                label => $label,
                entries => \@entries,
                toc_name => $name,
            });
        }

        return join("\n", @toc_sections);
    }

    method _render_matter($path, $class_name) {
        return '' unless $path;

        my %type_for_class = (
            'cp-cover' => 'cover',
            'cp-front-matter' => 'frontmatter',
            'cp-back-matter' => 'backmatter',
        );
        my $data_type = $type_for_class{$class_name};
        my $data_attr = $data_type ? qq{ data-type="$data_type"} : '';

        my $resolved = expand_tilde($path);
        unless (-f $resolved) {
            warn("HTML5 matter file not found: $resolved\n");
            return '';
        }

        if ($resolved =~ /\.(pdf)\z/i) {
            warn("HTML5 matter file is PDF (unsupported): $resolved\n");
            return '';
        }

        if ($resolved =~ /\.(html?|xhtml)\z/i) {
            open my $fh, '<:utf8', $resolved or do {
                warn("Cannot read HTML5 matter file: $resolved\n");
                return '';
            };
            local $/;
            my $content = <$fh> // '';
            close $fh;
            return qq{<section class="$class_name cp-matter"$data_attr>$content</section>};
        }

        my $image_html = $self->render_image($resolved, { class => 'cp-matter-image' });
        return qq{<section class="$class_name cp-matter"$data_attr>$image_html</section>};
    }

    # =================================================================
    # HTML-SPECIFIC OVERRIDES - Layout Directives
    # =================================================================

    # Override layout directive handlers for HTML
    method handle_newpage($elt) {
        my $break_class = $self->_newpage_break_class();
        return qq{<div class="cp-new-page$break_class"></div>\n};
    }

    method handle_new_page($elt) {
        return $self->handle_newpage($elt);
    }

    method handle_new_physical_page($elt) {
        # In HTML, physical page is same as logical page
        return $self->handle_newpage($elt);
    }

    # =================================================================
    # PAGED BREAK HELPERS
    # =================================================================

    method _is_paged_mode() {
        my $config = $self->config // {};
        my $mode = lc(eval { $config->{html5}->{mode} } // '');
        return ($mode eq 'print' || $mode eq 'paged');
    }

    method _parse_break_setting($setting, $default_mode = 'none') {
        my $value = lc($setting // '');
        return { mode => $default_mode, target => 'page' } if $value eq '';

        if ($value =~ /^(none|before|after|both)\z/) {
            return { mode => $1, target => 'page' };
        }

        if ($value =~ /^(right|left|recto|verso|page)\z/) {
            return { mode => 'before', target => $1 };
        }

        if ($value =~ /^(before|after|both)-(right|left|recto|verso|page)\z/) {
            return { mode => $1, target => $2 };
        }

        return { mode => $default_mode, target => 'page' };
    }

    method _break_class($position, $target) {
        return '' unless $position;
        $target //= 'page';
        return "cp-page-break-$position" if $target eq 'page';
        return "cp-page-break-$position-$target";
    }

    method _break_classes_for_setting($setting, $default_mode = 'none') {
        my $parsed = $self->_parse_break_setting($setting, $default_mode);
        my $mode = $parsed->{mode} // 'none';
        my $target = $parsed->{target} // 'page';
        return [] if $mode eq 'none';

        my @classes;
        if ($mode eq 'before' || $mode eq 'both') {
            my $class = $self->_break_class('before', $target);
            push @classes, $class if $class;
        }
        if ($mode eq 'after' || $mode eq 'both') {
            my $class = $self->_break_class('after', $target);
            push @classes, $class if $class;
        }

        return \@classes;
    }

    method _break_classes_for_setting_positions($setting, $default_mode = 'none') {
        my $parsed = $self->_parse_break_setting($setting, $default_mode);
        my $mode = $parsed->{mode} // 'none';
        my $target = $parsed->{target} // 'page';
        my %classes = ( before => [], after => [] );
        return \%classes if $mode eq 'none';

        if ($mode eq 'before' || $mode eq 'both') {
            my $class = $self->_break_class('before', $target);
            push @{ $classes{before} }, $class if $class;
        }
        if ($mode eq 'after' || $mode eq 'both') {
            my $class = $self->_break_class('after', $target);
            push @{ $classes{after} }, $class if $class;
        }

        return \%classes;
    }

    method _newpage_break_class() {
        return '' unless $self->_is_paged_mode();

        my $config = $self->config // {};
        my $setting = eval { $config->{html5}->{paged}->{newpage}->{'page-break'} } // 'page';
        my $classes = $self->_break_classes_for_setting($setting, 'before');
        return '' unless @$classes;
        return ' ' . join(' ', @$classes);
    }

    method handle_colb($elt) {
        return qq{<div style="column-break-before: always;"></div>\n};
    }

    method handle_column_break($elt) {
        return $self->handle_colb($elt);
    }

    method handle_columns($elt) {
        my $num = $elt->{value} // 1;
        if ($num > 1) {
            return qq{<div style="column-count: $num;">\n};
        } else {
            return qq{</div><!-- end columns -->\n};
        }
    }

    # =================================================================
    # HTML-SPECIFIC OVERRIDES - Text Formatting
    # =================================================================

    # Override text formatting helpers
    method wrap_bold($text) {
        return qq{<strong>$text</strong>};
    }

    method wrap_italic($text) {
        return qq{<em>$text</em>};
    }

    method wrap_monospace($text) {
        return qq{<code>$text</code>};
    }

    # Override escape_text for HTML
    method escape_text($text) {
        return '' unless defined $text;

        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        $text =~ s/'/&#39;/g;

        return $text;
    }

    # Process text with Pango-style markup support
    method process_text_with_markup($text) {
        return '' unless defined $text;
        
        # Check if text contains markup tags
        if ($text =~ /</) {
            my $layout = Text::Layout::HTML->new;
            $layout->set_markup($text);
            return $layout->render;
        }
        
        # Plain text - just escape
        return $self->escape_text($text);
    }

    # =================================================================
    # CHORD DIAGRAM RENDERING
    # =================================================================

    method render_chord_diagrams($song) {
        my $cfg = $self->config // {};
        my $diagrams_cfg = $cfg->{diagrams} // {};
        
        # Check if diagrams should be shown
        my $show = $diagrams_cfg->{show} // 'all';
        return '' if $show eq 'none';
        
        # Get list of chords to display
        my @chord_names;
        if ($song->{chords} && $song->{chords}->{chords}) {
            @chord_names = @{$song->{chords}->{chords}};
        } else {
            return '';
        }
        
        # Filter based on 'show' setting
        my @chords_to_display;
        my $suppress = $diagrams_cfg->{suppress} // [];
        my %suppress = map { $_ => 1 } @$suppress;
        
        foreach my $chord_name (@chord_names) {
            next if $suppress{$chord_name};
            
            my $info = $song->{chordsinfo}->{$chord_name};
            next unless $info;
            next if $info->can('is_annotation') && $info->is_annotation;
            next unless $info->can('has_diagram') && $info->has_diagram;
            
            # Skip if show=user and chord is not user-defined
            next if $show eq 'user' && !$info->{diagram};
            
            push @chords_to_display, { name => $chord_name, info => $info };
        }
        
        return '' unless @chords_to_display;
        
        # Sort if requested
        if ($diagrams_cfg->{sorted}) {
            @chords_to_display = sort { 
                ($a->{info}->{root_ord} // 0) <=> ($b->{info}->{root_ord} // 0)
                || $a->{name} cmp $b->{name}
            } @chords_to_display;
        }
        
        # Generate SVG diagrams
        my @diagrams;
        foreach my $chord (@chords_to_display) {
            my $svg = $svg_generator->generate_diagram($chord->{name}, $chord->{info});
            push @diagrams, $svg if $svg;
        }
        
        return '' unless @diagrams;
        
        # Use template to render
                my $html5_diagrams = eval { $cfg->{html5}->{diagrams} } // {};
                my $pdf_diagrams = eval { $cfg->{pdf}->{diagrams} } // {};
                my $align = lc( eval { $html5_diagrams->{align} }
                    // eval { $pdf_diagrams->{align} }
                    // 'left' );
                $align = 'left' unless $align =~ /^(?:left|right|center|spread)\z/;

                return $self->_process_template('chord_diagrams', {
                        diagrams => \@diagrams,
                        diagrams_align => $align,
                });
    }

    # =================================================================
    # CSS GENERATION
    # =================================================================

    method _build_css_vars($paged_mode = 0) {
        my $config = $self->config;
        my $html5_cfg = $config->{html5};

        # Extract and clone CSS sub-configs to plain hashes (avoid restricted hash issues)
        my $css_config = $html5_cfg->{css};
        my $colors_cfg = $css_config->{colors};
        my $fonts_cfg = $css_config->{fonts};
        my $sizes_cfg = $css_config->{sizes};
        my $spacing_cfg = $css_config->{spacing};

        # Resolve PDF config -> CSS (Phase 4)
        my $theme = $self->_resolve_theme_colors();
        my $spacing = $self->_resolve_spacing();
        my $chorus_styles = $self->_resolve_chorus_styles();
        my $grid_styles = $self->_resolve_grid_styles();

        my $vars = {
            # Phase 4: PDF config compatibility
            theme => $theme,
            spacing => $spacing,
            chorus_styles => $chorus_styles,
            grid_styles => $grid_styles,

            # CSS customization from config (Phase 3 user overrides)
            # Deep clone to plain hashes to avoid restricted hash issues in templates
            colors => { %$colors_cfg },
            fonts => { %$fonts_cfg },
            sizes => { %$sizes_cfg },
            chords_under => is_true($config->{settings}->{'chords-under'}),

            # Paged mode flag
            paged_mode => $paged_mode,
        };

        if ($paged_mode) {
            my $paged_cfg = $html5_cfg->{paged};
            my $pdf_cfg = $config->{pdf};

            $vars->{papersize} = eval { $paged_cfg->{papersize} }
                // $pdf_cfg->{papersize}
                // 'a4';
            $vars->{margintop} = eval { $paged_cfg->{margintop} }
                // $pdf_cfg->{margintop}
                // 80;
            $vars->{marginbottom} = eval { $paged_cfg->{marginbottom} }
                // $pdf_cfg->{marginbottom}
                // 40;
            $vars->{marginleft} = eval { $paged_cfg->{marginleft} }
                // $pdf_cfg->{marginleft}
                // 40;
            $vars->{marginright} = eval { $paged_cfg->{marginright} }
                // $pdf_cfg->{marginright}
                // 40;
            $vars->{headspace} = eval { $paged_cfg->{headspace} }
                // $pdf_cfg->{headspace}
                // 60;
            $vars->{footspace} = eval { $paged_cfg->{footspace} }
                // $pdf_cfg->{footspace}
                // 20;

            my $format_generator = ChordPro::Output::HTML5Helper::FormatGenerator->new(
                config => $config,
                options => $self->options,
            );
            $vars->{format_rules} = $format_generator->generate_rules();
        }

        return $vars;
    }

    method _process_template_file($template, $vars) {
        my $output = '';
        $template_engine->process($template, $vars, \$output)
            || die "Template error ($template): " . $template_engine->error();
        return $output;
    }

    method _paged_bundle_settings($paged_mode) {
        return { enabled => 0 } unless $paged_mode;

        my $config = $self->config // {};
        my $bundle = eval { $config->{html5}->{paged}->{bundle} };
        return { enabled => 0 } unless defined $bundle;

        if (!is_hashref($bundle)) {
            my $value = lc("$bundle");
            return { enabled => 1, mode => 'minimal', css => {} }
                if $value eq 'minimal';
            return { enabled => is_true($bundle), mode => 'minimal', css => {} };
        }

        my $enabled = is_true(eval { $bundle->{enabled} } // 0);
        my $mode = lc(eval { $bundle->{mode} } // 'minimal');
        my $css = eval { $bundle->{css} };
        $css = {} unless is_hashref($css);

        return {
            enabled => $enabled,
            mode => $mode,
            css => { %$css },
            html => eval { $bundle->{html} },
        };
    }

    method _write_text_file($path, $content) {
        my $fh = fs_open($path, '>:utf8');
        print {$fh} $content;
        close $fh;
    }

    method _condense_html_output($output) {
        return '' unless defined $output;
        $output =~ s/\n[ \t]*\n(?:[ \t]*\n)+/\n\n/g;
        return $output;
    }

    method generate_paged_css_assets($mode = 'minimal') {
        my $vars = $self->_build_css_vars(1);

        return {
            layout => $self->_process_template_file('html5/paged/css/layout.tt', $vars),
            content => $self->_process_template_file('html5/paged/css/content.tt', $vars),
        };
    }

    # =================================================================
    # CONFIGURATION RESOLUTION (Phase 4 - PDF Config Compatibility)
    # =================================================================

    method _resolve_theme_colors() {
        my $config = $self->config // {};
        my $pdf_theme = eval { $config->{pdf}->{theme} } // {};
        my $html_theme = eval { $config->{html5}->{theme} } // {};
        
        # HTML5 overrides PDF, with fallback defaults
        # Use eval{} for each key access due to restricted hashes
        my $fg = eval { $html_theme->{foreground} } // eval { $pdf_theme->{foreground} } // 'black';
        my $fg_med = eval { $html_theme->{'foreground-medium'} } // eval { $pdf_theme->{'foreground-medium'} } // '#888';
        my $fg_light = eval { $html_theme->{'foreground-light'} } // eval { $pdf_theme->{'foreground-light'} } // '#ddd';
        my $bg = eval { $html_theme->{background} } // eval { $pdf_theme->{background} } // 'white';
        
        return {
            foreground => $self->_convert_color_to_css($fg),
            'foreground-medium' => $self->_convert_color_to_css($fg_med),
            'foreground-light' => $self->_convert_color_to_css($fg_light),
            background => $self->_convert_color_to_css($bg),
        };
    }

    method _resolve_spacing() {
        my $config = $self->config // {};
        my $pdf_spacing = eval { $config->{pdf}->{spacing} } // {};
        my $html_spacing = eval { $config->{html5}->{spacing} } // {};
        
        # HTML5 overrides PDF, with fallback defaults
        # Use eval{} for each key access due to restricted hashes
        return {
            title => eval { $html_spacing->{title} } // eval { $pdf_spacing->{title} } // 1.2,
            lyrics => eval { $html_spacing->{lyrics} } // eval { $pdf_spacing->{lyrics} } // 1.2,
            chords => eval { $html_spacing->{chords} } // eval { $pdf_spacing->{chords} } // 1.2,
            diagramchords => eval { $html_spacing->{diagramchords} } // eval { $pdf_spacing->{diagramchords} } // 1.2,
            grid => eval { $html_spacing->{grid} } // eval { $pdf_spacing->{grid} } // 1.2,
            tab => eval { $html_spacing->{tab} } // eval { $pdf_spacing->{tab} } // 1,
            toc => eval { $html_spacing->{toc} } // eval { $pdf_spacing->{toc} } // 1.4,
            empty => eval { $html_spacing->{empty} } // eval { $pdf_spacing->{empty} } // 1,
        };
    }

    method _resolve_chorus_styles() {
        my $config = $self->config // {};
        my $pdf_chorus = eval { $config->{pdf}->{chorus} } // {};
        my $html_chorus = eval { $config->{html5}->{chorus} } // {};
        
        my $pdf_bar = eval { $pdf_chorus->{bar} } // {};
        my $html_bar = eval { $html_chorus->{bar} } // {};
        
        my $bar_color = eval { $html_bar->{color} } // eval { $pdf_bar->{color} } // 'foreground';
        
        # Resolve color references to theme colors
        if ($bar_color eq 'foreground' || $bar_color eq 'foreground-medium' || $bar_color eq 'foreground-light') {
            my $theme = $self->_resolve_theme_colors();
            $bar_color = $theme->{$bar_color} // $theme->{foreground};
        }
        
        return {
            indent => eval { $html_chorus->{indent} } // eval { $pdf_chorus->{indent} } // 0,
            bar_offset => eval { $html_bar->{offset} } // eval { $pdf_bar->{offset} } // 8,
            bar_width => eval { $html_bar->{width} } // eval { $pdf_bar->{width} } // 1,
            bar_color => $self->_convert_color_to_css($bar_color),
        };
    }

    method _resolve_grid_styles() {
        my $config = $self->config // {};
        my $pdf_grids = eval { $config->{pdf}->{grids} } // {};
        my $html_grids = eval { $config->{html5}->{grids} } // {};
        
        my $pdf_symbols = eval { $pdf_grids->{symbols} } // {};
        my $html_symbols = eval { $html_grids->{symbols} } // {};
        
        my $pdf_volta = eval { $pdf_grids->{volta} } // {};
        my $html_volta = eval { $html_grids->{volta} } // {};
        
        return {
            symbols_color => $self->_convert_color_to_css(
                eval { $html_symbols->{color} } // eval { $pdf_symbols->{color} } // 'blue'
            ),
            volta_color => $self->_convert_color_to_css(
                eval { $html_volta->{color} } // eval { $pdf_volta->{color} } // 'blue'
            ),
        };
    }

    method _convert_color_to_css($color) {
        # Pass through: hex colors, CSS color names, rgb(), rgba(), etc.
        # No conversion needed - CSS accepts most color formats
        return $color;
    }

    # =================================================================
    # CSS GENERATION
    # =================================================================

    method generate_default_css($paged_mode = 0) {
        my $config = $self->config;
        my $html5_cfg = $config->{html5};
        my $vars = $self->_build_css_vars($paged_mode);
        
        # Process CSS template (use paged CSS template if in paged mode)
        my $css = '';
        my $template;
        if ($paged_mode) {
            # Try paged template first, fall back to paged base
            my $paged_cfg = $html5_cfg->{paged};
            $template = $paged_cfg->{templates}->{css}
                     // 'html5/paged/css/base.tt';
        } else {
            $template = $html5_cfg->{templates}->{css}
                     // 'html5/css/base.tt';
        }
        
        $template_engine->process($template, $vars, \$css)
            || die "CSS Template error: " . $template_engine->error();
        
        # Append custom CSS if configured
        if (my $custom_file = eval { $html5_cfg->{css}->{'custom-css-file'} }) {
            if (-f $custom_file) {
                open my $fh, '<:utf8', $custom_file or warn "Can't load custom CSS: $!";
                if ($fh) {
                    local $/;
                    $css .= "\n\n/* User Custom CSS */\n" . <$fh>;
                    close $fh;
                }
            }
        }
        
        return $css;
    }
}

sub _song_sort_value {
    my ( $song, $field ) = @_;
    my $meta = $song->{meta} // {};

    if ( $field eq 'title' ) {
        $meta->{sorttitle} = $meta->{title} if !defined $meta->{sorttitle};
        $field = 'sorttitle';
    }

    my $values = $meta->{$field};
    return undef unless $values && ref($values) eq 'ARRAY';
    return $values->[0];
}

sub _compare_song_sort {
    my ( $a, $b, $fields, $collator ) = @_;

    foreach my $field (@$fields) {
        my $a_val = _song_sort_value( $a, $field->{name} );
        my $b_val = _song_sort_value( $b, $field->{name} );

        my $a_missing = !defined($a_val) || $a_val eq '';
        my $b_missing = !defined($b_val) || $b_val eq '';

        if ( $a_missing || $b_missing ) {
            next if $a_missing && $b_missing;
            return $a_missing ? 1 : -1;
        }

        my $cmp = $collator->cmp( fc($a_val), fc($b_val) );
        $cmp = -$cmp if $field->{desc};
        return $cmp if $cmp;
    }

    return 0;
}

sub _sorted_songbook_songs {
    my ( $songs, $sorting ) = @_;
    return $songs unless $songs && ref($songs) eq 'ARRAY';

    my @fields;
    if ( ref($sorting) eq 'ARRAY' ) {
        @fields = @$sorting;
    }
    elsif ( is_true($sorting) ) {
        my $spec = "$sorting";
        $spec = 'title' if $spec =~ /^(1|true|yes)$/i;
        @fields = split( /\s*,\s*/, $spec );
    }
    else {
        return $songs;
    }

    my @normalized;
    for my $field (@fields) {
        next unless defined $field;
        $field =~ s/^\s+|\s+$//g;
        next unless $field ne '';

        my $desc = ( $field =~ s/^-// );
        $field =~ s/^\+//;
        push @normalized, { name => lc($field), desc => $desc };
    }

    return $songs unless @normalized;

    my $collator = Unicode::Collate->new;
    my @sorted = sort { _compare_song_sort( $a, $b, \@normalized, $collator ) } @$songs;
    return \@sorted;
}

# =================================================================
# COMPATIBILITY WRAPPER - ChordPro calls as class method
# =================================================================

# This sub is called by ChordPro as a class method.
# It creates an instance and generates output using templates (following LaTeX.pm pattern).
sub generate_songbook {
    my ( $pkg, $sb ) = @_;

    # Create instance with config/options from global variables
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );

    # Check if paged mode is active
    my $config = $main::config;
    my $paged_mode = 0;
    if ($config && is_hashref($config)) {
        my $html5_cfg = eval { $config->{html5} };
        if ($html5_cfg && is_hashref($html5_cfg)) {
            my $mode = eval { $html5_cfg->{mode} } // '';
            $paged_mode = 1 if $mode eq 'print' || $mode eq 'paged';
        }
    }

    # Render songbook matter (cover/front/back) if configured
    my $cover_html = '';
    my $front_matter_html = '';
    my $back_matter_html = '';
    if ($config && is_hashref($config)) {
        my $html5_cfg = eval { $config->{html5} } // {};
        $cover_html = $backend->_render_matter(eval { $html5_cfg->{cover} }, 'cp-cover');
        $front_matter_html = $backend->_render_matter(
            eval { $html5_cfg->{'front-matter'} } // eval { $html5_cfg->{front_matter} },
            'cp-front-matter'
        );
        $back_matter_html = $backend->_render_matter(
            eval { $html5_cfg->{'back-matter'} } // eval { $html5_cfg->{back_matter} },
            'cp-back-matter'
        );
    }

    my $songs = $sb->{songs} // [];
    if ($config && is_hashref($config)) {
        my $sorting = eval { $config->{html5}->{songbook}->{'sort-songs'} };
        $sorting = eval { $config->{pdf}->{songbook}->{'sort-songs'} } unless defined $sorting;
        $sorting = eval { $config->{html5}->{sortby} } unless defined $sorting;
        $sorting = eval { $config->{pdf}->{sortby} } unless defined $sorting;

        my $sorted = _sorted_songbook_songs( $songs, $sorting );
        if ($sorted && ref($sorted) eq 'ARRAY') {
            $songs = $sorted;
            $sb->{songs} = $songs;
        }
    }

    # Process each song (returns HTML strings)
    my @songs_html;
    my $song_index = 0;
    my $song_break_before = '';
    my $song_break_after = '';
    if ($paged_mode) {
        my $break_setting = eval { $config->{html5}->{paged}->{song}->{'page-break'} } // 'none';
        my $classes = $backend->_break_classes_for_setting_positions($break_setting, 'none');
        $song_break_before = join(' ', @{ $classes->{before} }) if @{ $classes->{before} };
        $song_break_after = join(' ', @{ $classes->{after} }) if @{ $classes->{after} };
    }

    foreach my $song ( @{$songs} ) {
        $song_index++;
        $song->{meta} //= {};
        $song->{meta}->{songindex} //= [ $song_index ];
        my $song_id = "cp-song-$song_index";
        $song->{meta}->{html5_id} = [ $song_id ];

        my $before_break_html = '';
        my $song_page_break_class = $song_break_after;
        if ($paged_mode && $song_index > 1 && $song_break_before) {
            $before_break_html = qq{<div class="cp-song-break $song_break_before" aria-hidden="true">&nbsp;</div>\n};
        }

        my $song_html = $backend->generate_song(
            $song,
            $paged_mode,
            $song_id,
            $song_page_break_class,
        );

        push @songs_html, $before_break_html . $song_html;
    }

    my $bundle = $backend->_paged_bundle_settings($paged_mode);
    if ($bundle->{enabled}) {
        my $output_path = $options->{output} // '';
        if (!$output_path || $output_path eq '-') {
            warn("HTML5 bundle output requires a file path; falling back to inline output.\n");
        } else {
            my ($base, $dir, $ext) = fileparse($output_path, qr/\.[^.]*$/);
            my $bundle_dir = $ext ? File::Spec->catdir($dir, $base) : $output_path;
            make_path($bundle_dir) unless -d $bundle_dir;

            my $html_name = $bundle->{html} // ($ext ? "$base$ext" : 'index.html');
            my $html_path = File::Spec->catfile($bundle_dir, $html_name);

            my $mode = $bundle->{mode} // 'minimal';
            my $css_assets = $backend->generate_paged_css_assets($mode);
            my $layout_name = $bundle->{css}->{layout} // 'layout.css';
            my $content_name = $bundle->{css}->{content} // 'content.css';
            $backend->_write_text_file(File::Spec->catfile($bundle_dir, $layout_name), $css_assets->{layout});
            $backend->_write_text_file(File::Spec->catfile($bundle_dir, $content_name), $css_assets->{content});
            my $css_files = [ $layout_name, $content_name ];

            my $vars = {
                title => $sb->{title} // $songs->[0]->{title} // 'Songbook',
                cover_html => '',
                front_matter_html => '',
                back_matter_html => '',
                toc_html => '',
                songs => \@songs_html,
                css_files => $css_files,
                paged_mode => $paged_mode,
            };

            my $output = $backend->_process_template('paged_songbook', $vars);
            $output = $backend->_condense_html_output($output);
            $backend->_write_text_file($html_path, $output);
            return [];
        }
    }

    # Generate CSS
    my $css = $backend->generate_default_css($paged_mode);

    # Prepare template variables
    my $vars = {
        title => $sb->{title} // $songs->[0]->{title} // 'Songbook',
        cover_html => $cover_html,
        front_matter_html => $front_matter_html,
        back_matter_html => $back_matter_html,
        toc_html => $backend->_generate_toc($songs, $paged_mode),
        songs => \@songs_html,
        css => $css,
        paged_mode => $paged_mode,
    };

    # Process songbook template (use paged template if in paged mode)
    my $output = $backend->_process_template(
        $paged_mode ? 'paged_songbook' : 'songbook', 
        $vars
    );
    $output = $backend->_condense_html_output($output);

    # Return as array ref of lines (ChordPro joins with \n on write)
    my @lines = split(/\n/, $output);
    return \@lines;
}

# =================================================================
# TEXT::LAYOUT::HTML - Markup renderer for HTML output
# =================================================================

package Text::Layout::HTML;

use parent 'Text::Layout';
use ChordPro::Utils qw(fq);

sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self->{_currentfont} = { 
        family => 'default',
        style => 'normal',
        weight => 'normal' 
    };
    $self->{_currentcolor} = 'black';
    $self->{_currentsize} = 12;
    $self;
}

sub html {
    my $t = shift;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t;
}

sub render {
    my ( $self ) = @_;
    my $res = "";
    
    foreach my $fragment ( @{ $self->{_content} } ) {
        if ( $fragment->{type} eq 'strut' ) {
            next unless length($fragment->{label}//"");
            $res .= "<span id=\"".$fragment->{label}."\"></span>";
            next;
        }
        next unless length($fragment->{text});
        
        my $f = $fragment->{font} || $self->{_currentfont};
        my @c;  # styles
        my @d;  # decorations
        
        if ( $f->{style} eq "italic" ) {
            push( @c, q{font-style:italic} );
        }
        if ( $f->{weight} eq "bold" ) {
            push( @c, q{font-weight:bold} );
        }
        if ( $fragment->{color} && $fragment->{color} ne $self->{_currentcolor} ) {
            push( @c, join(":","color",$fragment->{color}) );
        }
        if ( $fragment->{size} && $fragment->{size} ne $self->{_currentsize} ) {
            push( @c, join(":","font-size",$fragment->{size}) );
        }
        if ( $fragment->{bgcolor} ) {
            push( @c, join(":","background-color",$fragment->{bgcolor}) );
        }
        if ( $fragment->{underline} ) {
            push( @d, q{underline} );
        }
        if ( $fragment->{strikethrough} ) {
            push( @d, q{line-through} );
        }
        push( @c, "text-decoration-line:".join(" ",@d) ) if @d;
        
        my $href = $fragment->{href} // "";
        $res .= "<a href=\"".html($href)."\">" if length($href);
        $res .= "<span style=\"" . join(";",@c) . "\">" if @c;
        $res .= html(fq($fragment->{text}));
        $res .= "</span>" if @c;
        $res .= "</a>" if length($href);
    }
    $res;
}

package ChordPro::Output::HTML5;

1;

=head1 NAME

ChordPro::Output::HTML5 - Modern HTML5 output backend for ChordPro

=head1 SYNOPSIS

    chordpro --generate=HTML5 -o song.html song.cho

=head1 DESCRIPTION

This is a modern HTML5 output backend for ChordPro that implements clean
separation of content and presentation using CSS.

Key features:

=over 4

=item * Object::Pad architecture with ChordProBase

=item * Flexbox-based chord positioning (works with any fonts)

=item * CSS variables for easy customization

=item * Responsive design with print media queries

=item * Embedded CSS (no external dependencies)

=item * Semantic HTML5 structure

=back

=head1 ARCHITECTURE

This backend extends ChordPro::Output::ChordProBase which provides:

=over 4

=item * Directive handler registry and dispatch

=item * Common ChordPro rendering methods

=item * Context tracking (verse, chorus, etc.)

=back

The HTML5 backend implements format-specific rendering:

=over 4

=item * HTML document structure

=item * CSS stylesheet generation

=item * Chord-lyric pair rendering with Flexbox

=item * HTML entity escaping

=back

=head1 CHORD POSITIONING

The core innovation is inline chord-lyric pairs with Flexbox:

    <div class="cp-songline">
      <span class="cp-chord-lyric-pair">
        <span class="cp-chord">C</span>
        <span class="cp-lyrics">Hel</span>
      </span>
      <span class="cp-chord-lyric-pair">
        <span class="cp-chord">G</span>
        <span class="cp-lyrics">lo</span>
      </span>
    </div>

This creates a structural relationship where chords stay above their
lyrics regardless of font families or sizes.

=head1 CSS CUSTOMIZATION

Users can override CSS variables:

    :root {
        --cp-font-text: 'Times New Roman', serif;
        --cp-font-chord: Helvetica, sans-serif;
        --cp-color-chord: #cc0000;
    }

=head1 SEE ALSO

L<ChordPro::Output::ChordProBase>, L<ChordPro::Output::Base>

=head1 AUTHOR

ChordPro Development Team

=cut
