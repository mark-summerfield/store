# Copyright © 2025 Mark Summerfield. All rights reserved.

package require gui_misc
package require ui

oo::define App method make_widgets {} {
    set panes [ttk::panedwindow .panes -orient horizontal]
    $panes add [my make_tabs]
    lassign [gui_misc::make_text_frame] textFrame Text
    $panes add $textFrame
    my make_status_bar
    my make_controls
    my layout_controls
}    

oo::define App method make_controls {} {
    set frm [ttk::frame .controlsFrame]
    ttk::button $frm.openButton -text "Open Store…" -underline 0 \
        -compound left -command [callback on_open] \
        -image [ui::icon document-open.svg $::ICON_SIZE]
    ttk::button $frm.addButton -text "Add Addable…" -underline 0 \
        -compound left -command [callback on_add_addable] \
        -image [ui::icon document-save-as.svg $::ICON_SIZE]
    ttk::button $frm.updateButton -text Update -underline 0 \
        -compound left -command [callback on_update] \
        -image [ui::icon document-save.svg $::ICON_SIZE]
    ttk::button $frm.extractButton -text Extract -underline 0 \
        -compound left -command [callback on_extract] \
        -image [ui::icon edit-copy.svg $::ICON_SIZE]
    ttk::button $frm.copyToButton -text "Copy To…" -underline 0 \
        -compound left -command [callback on_copy_to] \
        -image [ui::icon folder-new.svg $::ICON_SIZE]
    ttk::menubutton $frm.moreButton -text More -underline 0
    menu $frm.moreButton.menu
    $frm.moreButton.menu add command -label Tags… -underline 0 \
        -compound left -command [callback on_tags] \
        -image [ui::icon bookmark-new.svg $::ICON_SIZE]
    $frm.moreButton.menu add command -label Ignores… -underline 0 \
        -compound left -command [callback on_ignores] \
        -image [ui::icon document-properties.svg $::ICON_SIZE]
    $frm.moreButton.menu add separator
    $frm.moreButton.menu add command -label "Add Files…" -underline 0 \
        -compound left -command [callback on_add_files] \
        -image [ui::icon document-new.svg $::ICON_SIZE]
    $frm.moreButton.menu add separator
    $frm.moreButton.menu add command -label Restore… -underline 0 \
        -compound left -command [callback on_restore] \
        -image [ui::icon edit-undo.svg $::ICON_SIZE]
    $frm.moreButton.menu add command -label Clean -underline 1 \
        -compound left -command [callback on_clean] \
        -image [ui::icon edit-clear.svg $::ICON_SIZE]
    $frm.moreButton.menu add command -label Purge… -underline 0 \
        -compound left -command [callback on_purge] \
        -image [ui::icon edit-cut.svg $::ICON_SIZE]
    $frm.moreButton.menu add separator
    $frm.moreButton.menu add command -label Config… -underline 0 \
        -compound left -command [callback on_config] \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
    $frm.moreButton.menu add command -label About -underline 1 \
        -compound left -command [callback on_about] \
        -image [ui::icon about.svg $::ICON_SIZE]
    $frm.moreButton configure -menu $frm.moreButton.menu
    ttk::checkbutton $frm.showOptions -text "Show Options" \
        -underline 6 -onvalue 1 -offvalue 0 \
        -variable [my varname ShowOptions] \
        -command [callback on_show_options]
    ttk::frame $frm.showFrame -relief groove 
    ttk::radiobutton $frm.showFrame.asIsRadio -text "Show As-Is" \
        -underline 0 -value asis -variable [my varname ShowState] \
        -command [callback on_show_asis]
    ttk::checkbutton $frm.showFrame.withLinos -text "Line Nºs" \
        -underline 0 -onvalue 1 -offvalue 0 \
        -variable [my varname WithLinos] -command [callback on_with_linos]
    ttk::checkbutton $frm.showFrame.showAll -text "Show All" \
        -underline 1 -onvalue 1 -offvalue 0 \
        -variable [my varname ShowAll] -command [callback on_show_all]
    ttk::radiobutton $frm.showFrame.diffWithDiskRadio \
        -text "Diff with Disk" -underline 0 -value disk \
        -variable [my varname ShowState] \
        -command [callback on_show_diff_with_disk]
    ttk::radiobutton $frm.showFrame.diffToRadio -text "Diff to Gen.:" \
        -underline 5 -value generation -variable [my varname ShowState] \
        -command [callback on_show_diff_to]
    ttk::checkbutton $frm.showFrame.inContextCheck -text "In Context" \
        -underline 0 -onvalue 1 -offvalue 0 \
        -variable [my varname InContext] -command [callback on_in_context]
    ttk::label $frm.showFrame.diffLabel -text @
    ttk::spinbox $frm.showFrame.diffGenSpinbox -format %.0f -from 0 \
        -to 99999 -width 5 -command [callback on_show_diff_to]
    $frm.showFrame.diffGenSpinbox set 0
    ui::apply_edit_bindings $frm.showFrame.diffGenSpinbox
    ttk::frame $frm.findFrame -relief groove 
    ttk::label $frm.findFrame.findLabel -text Find: -underline 2
    set FindEntry [ttk::entry $frm.findFrame.findEntry -width 15]
    ui::apply_edit_bindings $FindEntry
    ttk::button $frm.quitButton -text Quit -underline 0 -compound left \
        -command [callback on_quit] -image [ui::icon quit.svg $::ICON_SIZE]
}

oo::define App method layout_controls {} {
    set opts "-padx $::PAD -pady $::PAD"
    set frm .controlsFrame
    pack $frm.openButton -side top {*}$opts
    pack $frm.addButton -side top {*}$opts
    pack $frm.updateButton -side top {*}$opts
    pack $frm.extractButton -side top {*}$opts
    pack $frm.copyToButton -side top {*}$opts
    pack $frm.moreButton -side top -ipadx [expr {$::PAD * 2}] {*}$opts
    pack $frm.showOptions -side top -fill x {*}$opts
    pack $frm.showFrame -side top -fill x {*}$opts
    grid $frm.showFrame.asIsRadio -row 0 -column 0 -columnspan 3 \
        -sticky w {*}$opts
    grid $frm.showFrame.showAll -row 1 -column 1 -sticky w \
        -columnspan 2 {*}$opts
    grid $frm.showFrame.withLinos -row 2 -column 1 -sticky w \
        -columnspan 2 {*}$opts
    grid $frm.showFrame.diffWithDiskRadio -row 3 -column 0 \
        -columnspan 3 -sticky w {*}$opts
    grid $frm.showFrame.diffToRadio -row 4 -column 0 -columnspan 3 \
        -sticky w {*}$opts
    grid $frm.showFrame.diffLabel -row 5 -column 1 -sticky e -pady $::PAD
    grid $frm.showFrame.diffGenSpinbox -row 5 -column 2 -columnspan 2 \
        -sticky w -pady $::PAD
    grid $frm.showFrame.inContextCheck -row 6 -column 1 -columnspan 2 \
        -sticky w {*}$opts
    pack $frm.findFrame -side top -fill x {*}$opts
    grid $frm.findFrame.findLabel -row 0 -column 0 -sticky w {*}$opts
    grid $frm.findFrame.findEntry -row 1 -column 0 -sticky w {*}$opts
    pack $frm.quitButton -side bottom {*}$opts
}

oo::define App method make_tabs {} {
    set Tabs [ttk::notebook .panes.tabs]
    ttk::notebook::enableTraversal $Tabs
    $Tabs add [my make_files_tree] -text Files -underline 0
    $Tabs add [my make_generations_tree] -text Generations -underline 0
    return $Tabs
}

oo::define App method make_files_tree {} {
    set frm [ttk::frame .panes.tabs.filenameTreeFrame]
    set name filenameTree
    set sa [scrollutil::scrollarea $frm.sa -xscrollbarmode none]
    set FilenameTree [ttk::treeview $frm.sa.$name -show tree \
        -selectmode browse]
    ui::apply_treeview_bindings $FilenameTree
    $sa setwidget $FilenameTree
    pack $sa -fill both -expand 1
    gui_misc::set_tree_tags $FilenameTree
    return $frm
}

oo::define App method make_generations_tree {} {
    set frm [ttk::frame .panes.tabs.generationTreeFrame]
    set name generationTree
    set sa [scrollutil::scrollarea $frm.sa -xscrollbarmode none]
    set GenerationTree [ttk::treeview $frm.sa.$name \
        -columns {Created Message}]
    ui::apply_treeview_bindings $GenerationTree
    $sa setwidget $GenerationTree
    pack $sa -fill both -expand 1
    $GenerationTree configure -show tree -selectmode browse
    $GenerationTree column #0 -stretch 0
    $GenerationTree column 0 -stretch 0
    $GenerationTree column 1 -stretch 1
    gui_misc::set_tree_tags $GenerationTree
    return $frm
}

oo::define App method make_status_bar {} {
    if {$StoreFilename ne ""} {
        set message "Read \"$StoreFilename\""
        set ms $::MEDIUM_WAIT
    } else {
        set message "Click Open Store… to choose a store"
        set ms $::LONG_WAIT
    }
    set frm [ttk::frame .statusFrame]
    set StatusInfoLabel [ttk::label $frm.statusInfoLabel -relief sunken \
                         -text $message]
    set StatusAddableLabel [ttk::label $frm.statusAddableLabel \
                            -relief sunken]
    set StatusUpdatableLabel [ttk::label $frm.statusUpdatableLabel \
                              -relief sunken]
    set StatusCleanableLabel [ttk::label $frm.statusCleanableLabel \
                              -relief sunken]
    set StatusSizeLabel [ttk::label $frm.statusSizeLabel -relief sunken]
    pack $frm.statusInfoLabel -side left -fill x -expand 1
    pack $frm.statusSizeLabel -side right -fill x
    pack $frm.statusCleanableLabel -side right -fill x
    pack $frm.statusUpdatableLabel -side right -fill x
    pack $frm.statusAddableLabel -side right -fill x
    after $ms [callback set_status_info]
    my report_status
}

oo::define App method make_layout {} {
    grid .panes -column 0 -row 0 -sticky news
    grid .controlsFrame -column 1 -row 0 -sticky ns
    grid .statusFrame -row 1 -columnspan 2 -sticky ew -pady $::PAD
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 0 -weight 1

}

oo::define App method make_bindings {} {
    bind $Tabs <<NotebookTabChanged>> [callback on_tab_changed]
    bind $FilenameTree <<TreeviewSelect>> [callback on_filename_tree_select]
    bind $GenerationTree <<TreeviewSelect>> \
        [callback on_generation_tree_select]
    bind .controlsFrame.findFrame.findEntry <Return> [callback on_find]
    bind .controlsFrame.showFrame.diffToRadio <Return> \
            [callback on_show_diff_to]
    bind .controlsFrame.showFrame.diffGenSpinbox <Return> \
        {.controlsFrame.showFrame.diffToRadio invoke}
    bind .controlsFrame.showFrame.diffGenSpinbox <<Increment>> \
        {.controlsFrame.showFrame.diffToRadio invoke}
    bind .controlsFrame.showFrame.diffGenSpinbox <<Decrement>> \
        {.controlsFrame.showFrame.diffToRadio invoke}
    bind . <KP_Enter> [callback on_find]
    bind . <F3> [callback on_find]
    bind . <Alt-a> [callback on_add_addable]
    bind . <Alt-c> [callback on_copy_to]
    bind . <Alt-d> {.controlsFrame.showFrame.diffWithDiskRadio invoke}
    bind . <Alt-e> [callback on_extract]
    bind . <Alt-h> {.controlsFrame.showFrame.showAll invoke}
    bind . <Alt-i> {.controlsFrame.showFrame.inContextCheck invoke}
    bind . <Alt-l> {.controlsFrame.showFrame.withLinos invoke}
    bind . <Alt-m> {ui::popup_menu .controlsFrame.moreButton.menu \
                    .controlsFrame.moreButton}
    bind . <Alt-n> {focus .controlsFrame.findFrame.findEntry}
    bind . <Alt-o> [callback on_open]
    bind . <Alt-p> {.controlsFrame.showOptions invoke}
    bind . <Alt-q> [callback on_quit]
    bind . <Alt-s> {.controlsFrame.showFrame.asIsRadio invoke}
    bind . <Alt-t> {
        .controlsFrame.showFrame.diffToRadio invoke
        focus .controlsFrame.showFrame.diffGenSpinbox
    }
    bind . <Alt-u> [callback on_update]
}    

# — Copy/paste into Minicalc for keyboard accelerators —
# &Files
# Generations
# Open Store
# Add
# Update
# Extract
# Copy To
# &More
# Show as-is
# Diff with Disk
# Diff to Gen
# In Context
# Find
# Quit
