# generated by wxGlade 0.9.0pre on Sat Oct  3 20:45:11 2020
#
# To get wxPerl visit http://www.wxperl.it
#

use Wx qw[:allclasses];
use strict;

# begin wxGlade: dependencies
# end wxGlade

# begin wxGlade: extracode
# end wxGlade

package App::Music::ChordPro::Wx::PreferencesDialog_wxg;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

use Wx::Locale gettext => '_T';
sub new {
    my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $title  = ""                 unless defined $title;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    # begin wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::new
    $style = wxDEFAULT_DIALOG_STYLE|wxMAXIMIZE_BOX|wxRESIZE_BORDER
        unless defined $style;

    $self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{l_config} = Wx::StaticText->new($self, wxID_ANY, _T("Configuration"));
    $self->{ch_config} = Wx::CheckListBox->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("Default"), _T("Custom")], wxLB_EXTENDED|wxLB_NEEDED_SB);
    $self->{cb_skipstdcfg} = Wx::CheckBox->new($self, wxID_ANY, _T("Ignore standard configs"));
    $self->{l_cfgfile} = Wx::StaticText->new($self, wxID_ANY, _T("Custom config"));
    $self->{t_configfiledialog} = Wx::TextCtrl->new($self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, wxTE_READONLY);
    $self->{b_configfiledialog} = Wx::Button->new($self, wxID_ANY, _T("\N{U+2026}"), wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT);
    $self->{ch_editfont} = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("Monospaced"), _T("Serif"), _T("Sans Serif")], );
    $self->{sp_editfont} = Wx::SpinCtrl->new($self, wxID_ANY, "14", wxDefaultPosition, wxDefaultSize, wxSP_ARROW_KEYS, 4, 40, 14);
    $self->{l_notation} = Wx::StaticText->new($self, wxID_ANY, _T("Notation"));
    $self->{ch_notation} = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("Common (C, D, E, F, G, A, B)"), _T("German (C, D, E, F, G, A, H)"), _T("Latin (Do, Re, Mi, Fa, Sol, ...)"), _T("Solf\N{U+00e8}ge (Do, Re, Mi, Fa, So, ...)"), _T("Nashville (0, 1, 2, ...)"), _T("Roman (I, II, III, ...)")], );
    $self->{l_xpose} = Wx::StaticText->new($self, wxID_ANY, _T("Transpose"));
    $self->{l_xpose_from} = Wx::StaticText->new($self, wxID_ANY, _T("From"));
    $self->{ch_xpose_from} = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("C"), _T("C#"), _T("Db"), _T("D"), _T("D#"), _T("Eb"), _T("E"), _T("F"), _T("F#"), _T("Gb"), _T("G"), _T("G#"), _T("Ab"), _T("A"), _T("A#"), _T("Bb"), _T("B")], );
    $self->{l_xpose_to} = Wx::StaticText->new($self, wxID_ANY, _T("To"));
    $self->{ch_xpose_to} = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("C"), _T("C#"), _T("Db"), _T("D"), _T("D#"), _T("Eb"), _T("E"), _T("F"), _T("F#"), _T("Gb"), _T("G"), _T("G#"), _T("Ab"), _T("A"), _T("A#"), _T("Bb"), _T("B")], );
    $self->{rb_xpose_sharp} = Wx::RadioButton->new($self, wxID_ANY, _T("Sharp"));
    $self->{rb_xpose_flat} = Wx::RadioButton->new($self, wxID_ANY, _T("Flat"));
    $self->{l_transcode} = Wx::StaticText->new($self, wxID_ANY, _T("Transcode to"));
    $self->{ch_transcode} = Wx::Choice->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, [_T("-----"), _T("Common (C, D, E, F, G, A, B)"), _T("German (C, D, E, F, G, A, H)"), _T("Latin (Do, Re, Mi, Fa, Sol, ...)"), _T("Solf\N{U+00e8}ge (Do, Re, Mi, Fa, So, ...)"), _T("Nashville (0, 1, 2, ...)"), _T("Roman (I, II, III, ...)")], );
    $self->{l_pdfviewer} = Wx::StaticText->new($self, wxID_ANY, _T("PDF previewer"));
    $self->{t_pdfviewer} = Wx::TextCtrl->new($self, wxID_ANY, "");
    $self->{b_prefs_cancel} = Wx::Button->new($self, wxID_CANCEL, "");
    $self->{b_prefs_ok} = Wx::Button->new($self, wxID_OK, "");

    $self->__set_properties();
    $self->__do_layout();

    Wx::Event::EVT_CHECKLISTBOX($self, $self->{ch_config}->GetId, $self->can('OnChConfig'));
    Wx::Event::EVT_CHECKBOX($self, $self->{cb_skipstdcfg}->GetId, $self->can('OnSkipStdCfg'));
    Wx::Event::EVT_BUTTON($self, $self->{b_configfiledialog}->GetId, $self->can('OnConfigFileDialog'));
    Wx::Event::EVT_CHOICE($self, $self->{ch_editfont}->GetId, $self->can('OnChEditFont'));
    Wx::Event::EVT_SPINCTRL($self, $self->{sp_editfont}->GetId, $self->can('OnSpEditFont'));
    Wx::Event::EVT_CHOICE($self, $self->{ch_notation}->GetId, $self->can('OnChNotation'));
    Wx::Event::EVT_CHOICE($self, $self->{ch_xpose_from}->GetId, $self->can('OnXposeFrom'));
    Wx::Event::EVT_CHOICE($self, $self->{ch_xpose_to}->GetId, $self->can('OnXposeTo'));
    Wx::Event::EVT_RADIOBUTTON($self, $self->{rb_xpose_sharp}->GetId, $self->can('OnXposeSharp'));
    Wx::Event::EVT_RADIOBUTTON($self, $self->{rb_xpose_flat}->GetId, $self->can('onXposeFlat'));
    Wx::Event::EVT_CHOICE($self, $self->{ch_transcode}->GetId, $self->can('OnChTranscode'));
    Wx::Event::EVT_BUTTON($self, $self->{b_prefs_cancel}->GetId, $self->can('OnCancel'));
    Wx::Event::EVT_BUTTON($self, $self->{b_prefs_ok}->GetId, $self->can('OnAccept'));

    # end wxGlade
    return $self;

}


sub __set_properties {
    my $self = shift;
    # begin wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::__set_properties
    $self->SetTitle(_T("Preferences"));
    $self->{ch_config}->SetMinSize($self->{ch_config}->ConvertDialogSizeToPixels(Wx::Size->new(130, 39)));
    $self->{ch_config}->SetSelection(0);
    $self->{cb_skipstdcfg}->SetToolTipString(_T("Ignore user and legacy configs, if any"));
    $self->{t_configfiledialog}->SetToolTipString(_T("Select a custom config file by pressing the [...] button."));
    $self->{b_configfiledialog}->SetMinSize($self->{b_configfiledialog}->ConvertDialogSizeToPixels(Wx::Size->new(38, 14)));
    $self->{ch_editfont}->SetSelection(0);
    $self->{ch_notation}->SetSelection(0);
    $self->{ch_xpose_from}->SetSelection(0);
    $self->{ch_xpose_to}->SetSelection(0);
    $self->{rb_xpose_sharp}->SetToolTipString(_T("Use sharp chords"));
    $self->{rb_xpose_flat}->SetToolTipString(_T("Use flat chords"));
    $self->{ch_transcode}->SetSelection(0);
    $self->{t_pdfviewer}->SetToolTipString(_T("Alternative PDF previewer.\n  %f will be replaced by the file name\n  %u will be replaced by the file URL\nLeave empty to use the system default viewer."));
    $self->{b_prefs_ok}->SetDefault();
    # end wxGlade
}

sub __do_layout {
    my $self = shift;
    # begin wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::__do_layout
    $self->{sz_prefs_outer} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sz_prefs_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_prefs_inner} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_2} = Wx::FlexGridSizer->new(10, 2, 5, 5);
    $self->{sz_xpose} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_3} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_configfile} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_2}->Add($self->{l_config}, 1, wxLEFT|wxTOP, 5);
    $self->{sizer_2}->Add($self->{ch_config}, 1, wxALIGN_CENTER_VERTICAL|wxEXPAND|wxRIGHT|wxTOP, 5);
    $self->{sizer_2}->Add(5, 5, 0, wxEXPAND, 0);
    $self->{sizer_2}->Add($self->{cb_skipstdcfg}, 0, wxALIGN_CENTER_VERTICAL, 0);
    $self->{sizer_2}->Add($self->{l_cfgfile}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sz_configfile}->Add($self->{t_configfiledialog}, 1, wxEXPAND, 0);
    $self->{sz_configfile}->Add($self->{b_configfiledialog}, 0, 0, 0);
    $self->{sizer_2}->Add($self->{sz_configfile}, 1, wxEXPAND|wxRIGHT, 5);
    my $static_line_1 = Wx::StaticLine->new($self, wxID_ANY);
    $self->{sizer_2}->Add($static_line_1, 0, wxEXPAND, 0);
    my $static_line_2 = Wx::StaticLine->new($self, wxID_ANY);
    $self->{sizer_2}->Add($static_line_2, 0, wxEXPAND, 0);
    my $l_edit = Wx::StaticText->new($self, wxID_ANY, _T("Editor font"));
    $self->{sizer_2}->Add($l_edit, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sizer_3}->Add($self->{ch_editfont}, 1, wxEXPAND, 0);
    $self->{sizer_3}->Add($self->{sp_editfont}, 0, 0, 0);
    $self->{sizer_2}->Add($self->{sizer_3}, 1, wxEXPAND, 0);
    my $static_line_3 = Wx::StaticLine->new($self, wxID_ANY);
    $self->{sizer_2}->Add($static_line_3, 0, wxEXPAND, 0);
    my $static_line_4 = Wx::StaticLine->new($self, wxID_ANY);
    $self->{sizer_2}->Add($static_line_4, 0, wxEXPAND, 0);
    $self->{sizer_2}->Add($self->{l_notation}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sizer_2}->Add($self->{ch_notation}, 0, wxALIGN_CENTER_VERTICAL|wxEXPAND|wxRIGHT, 5);
    $self->{sizer_2}->Add($self->{l_xpose}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sz_xpose}->Add($self->{l_xpose_from}, 0, wxALIGN_CENTER_VERTICAL|wxRIGHT, 5);
    $self->{sz_xpose}->Add($self->{ch_xpose_from}, 0, 0, 0);
    $self->{sz_xpose}->Add($self->{l_xpose_to}, 0, wxALIGN_CENTER_VERTICAL|wxFIXED_MINSIZE|wxLEFT|wxRIGHT, 5);
    $self->{sz_xpose}->Add($self->{ch_xpose_to}, 0, 0, 0);
    $self->{sz_xpose}->Add($self->{rb_xpose_sharp}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT|wxRIGHT, 5);
    $self->{sz_xpose}->Add($self->{rb_xpose_flat}, 0, wxALIGN_CENTER_VERTICAL, 0);
    $self->{sizer_2}->Add($self->{sz_xpose}, 1, wxEXPAND|wxRIGHT, 5);
    $self->{sizer_2}->Add($self->{l_transcode}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sizer_2}->Add($self->{ch_transcode}, 0, wxALIGN_CENTER_VERTICAL|wxEXPAND|wxRIGHT, 5);
    $self->{sizer_2}->Add($self->{l_pdfviewer}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 5);
    $self->{sizer_2}->Add($self->{t_pdfviewer}, 0, wxEXPAND|wxRIGHT, 5);
    $self->{sizer_2}->AddGrowableRow(0);
    $self->{sizer_2}->AddGrowableCol(1);
    $self->{sz_prefs_inner}->Add($self->{sizer_2}, 1, 0, 5);
    $self->{sz_prefs_outer}->Add($self->{sz_prefs_inner}, 1, wxEXPAND|wxLEFT|wxRIGHT|wxTOP, 0);
    $self->{sz_prefs_outer}->Add(1, 1, 0, wxEXPAND, 0);
    $self->{sz_prefs_buttons}->Add(5, 1, 1, wxEXPAND, 0);
    $self->{sz_prefs_buttons}->Add($self->{b_prefs_cancel}, 0, 0, 0);
    $self->{sz_prefs_buttons}->Add($self->{b_prefs_ok}, 0, wxLEFT, 5);
    $self->{sz_prefs_outer}->Add($self->{sz_prefs_buttons}, 0, wxALL|wxEXPAND, 5);
    $self->SetSizer($self->{sz_prefs_outer});
    $self->{sz_prefs_outer}->Fit($self);
    $self->Layout();
    # end wxGlade
}

sub OnChConfig {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnChConfig <event_handler>
    warn "Event handler (OnChConfig) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnSkipStdCfg {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnSkipStdCfg <event_handler>
    warn "Event handler (OnSkipStdCfg) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnConfigFileDialog {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnConfigFileDialog <event_handler>
    warn "Event handler (OnConfigFileDialog) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnChEditFont {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnChEditFont <event_handler>
    warn "Event handler (OnChEditFont) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnSpEditFont {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnSpEditFont <event_handler>
    warn "Event handler (OnSpEditFont) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnChNotation {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnChNotation <event_handler>
    warn "Event handler (OnChNotation) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnXposeFrom {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnXposeFrom <event_handler>
    warn "Event handler (OnXposeFrom) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnXposeTo {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnXposeTo <event_handler>
    warn "Event handler (OnXposeTo) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnXposeSharp {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnXposeSharp <event_handler>
    warn "Event handler (OnXposeSharp) not implemented";
    $event->Skip;
    # end wxGlade
}


sub onXposeFlat {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::onXposeFlat <event_handler>
    warn "Event handler (onXposeFlat) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnChTranscode {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnChTranscode <event_handler>
    warn "Event handler (OnChTranscode) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnCancel {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnCancel <event_handler>
    warn "Event handler (OnCancel) not implemented";
    $event->Skip;
    # end wxGlade
}


sub OnAccept {
    my ($self, $event) = @_;
    # wxGlade: App::Music::ChordPro::Wx::PreferencesDialog_wxg::OnAccept <event_handler>
    warn "Event handler (OnAccept) not implemented";
    $event->Skip;
    # end wxGlade
}


# end of class App::Music::ChordPro::Wx::PreferencesDialog_wxg

1;

