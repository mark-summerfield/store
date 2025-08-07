# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
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
    set frame [ttk::frame .controlsFrame]
    ttk::button $frame.openButton -text "Open Store…" -underline 0 \
        -compound left -command [callback on_open] \
        -image [ui::icon document-open.svg $::ICON_SIZE]
    ttk::button $frame.addButton -text "Add Addable…" -underline 0 \
        -compound left -command [callback on_add_addable] \
        -image [ui::icon document-save-as.svg $::ICON_SIZE]
    ttk::button $frame.updateButton -text Update -underline 0 \
        -compound left -command [callback on_update] \
        -image [ui::icon document-save.svg $::ICON_SIZE]
    ttk::button $frame.extractButton -text Extract -underline 0 \
        -compound left -command [callback on_extract] \
        -image [ui::icon edit-copy.svg $::ICON_SIZE]
    ttk::button $frame.copyToButton -text "Copy To…" -underline 0 \
        -compound left -command [callback on_copy_to] \
        -image [ui::icon folder-new.svg $::ICON_SIZE]
    ttk::menubutton $frame.moreButton -text More -underline 0
    menu $frame.moreButton.menu
    $frame.moreButton.menu add command -label Tags… -underline 0 \
        -compound left -command [callback on_tags] \
        -image [ui::icon bookmark-new.svg $::ICON_SIZE]
    $frame.moreButton.menu add command -label Ignores… -underline 0 \
        -compound left -command [callback on_ignores] \
        -image [ui::icon document-properties.svg $::ICON_SIZE]
    $frame.moreButton.menu add separator
    $frame.moreButton.menu add command -label "Add File…" -underline 0 \
        -compound left -command [callback on_add_file] \
        -image [ui::icon document-new.svg $::ICON_SIZE]
    $frame.moreButton.menu add separator
    $frame.moreButton.menu add command -label Restore… -underline 0 \
        -compound left -command [callback on_restore] \
        -image [ui::icon edit-undo.svg $::ICON_SIZE]
    $frame.moreButton.menu add command -label Clean -underline 0 \
        -compound left -command [callback on_clean] \
        -image [ui::icon edit-clear.svg $::ICON_SIZE]
    $frame.moreButton.menu add command -label Purge… -underline 0 \
        -compound left -command [callback on_purge] \
        -image [ui::icon edit-cut.svg $::ICON_SIZE]
    $frame.moreButton.menu add separator
    $frame.moreButton.menu add command -label About -underline 1 \
        -compound left -command [callback on_about] \
        -image [ui::icon about.svg $::ICON_SIZE]
    $frame.moreButton configure -menu $frame.moreButton.menu
    ttk::frame $frame.showFrame -relief groove 
    ttk::radiobutton $frame.showFrame.asIsRadio -text "Show As-Is" \
        -underline 0 -value asis -variable [my varname ShowState] \
        -command [callback on_show_asis]
    ttk::checkbutton $frame.showFrame.withLinos -text "Line Nºs" \
        -underline 0 -onvalue true -offvalue false \
        -variable [my varname WithLinos] -command [callback on_with_linos]
    ttk::radiobutton $frame.showFrame.diffWithDiskRadio \
        -text "Diff with Disk" -underline 0 -value disk \
        -variable [my varname ShowState] \
        -command [callback on_show_diff_with_disk]
    ttk::radiobutton $frame.showFrame.diffToRadio -text "Diff to Gen.:" \
        -underline 5 -value generation -variable [my varname ShowState] \
        -command [callback on_show_diff_to]
    ttk::checkbutton $frame.showFrame.inContextCheck -text "In Context" \
        -underline 0 -onvalue true -offvalue false \
        -variable [my varname InContext] -command [callback on_in_context]
    ttk::label $frame.showFrame.diffLabel -text @
    ttk::spinbox $frame.showFrame.diffGenSpinbox -format %.0f -from 0 \
        -to 99999 -width 5 -command [callback on_show_diff_to]
    $frame.showFrame.diffGenSpinbox set 0
    ttk::frame $frame.findFrame -relief groove 
    ttk::label $frame.findFrame.findLabel -text Find: -underline 2
    set FindEntry [ttk::entry $frame.findFrame.findEntry -width 15]
    ttk::button $frame.quitButton -text Quit -underline 0 -compound left \
        -command [callback on_quit] -image [ui::icon quit.svg $::ICON_SIZE]
}

oo::define App method layout_controls {} {
    set opts "-padx $::PAD -pady $::PAD"
    set frame .controlsFrame
    pack $frame.openButton -side top {*}$opts
    pack $frame.addButton -side top {*}$opts
    pack $frame.updateButton -side top {*}$opts
    pack $frame.extractButton -side top {*}$opts
    pack $frame.copyToButton -side top {*}$opts
    pack $frame.moreButton -side top -ipadx [expr {$::PAD * 2}] {*}$opts
    pack $frame.showFrame -side top -fill x {*}$opts
    grid $frame.showFrame.asIsRadio -row 0 -column 0 -columnspan 3 \
        -sticky w {*}$opts
    grid $frame.showFrame.withLinos -row 1 -column 1 -sticky w \
        -columnspan 2 {*}$opts
    grid $frame.showFrame.diffWithDiskRadio -row 2 -column 0 \
        -columnspan 3 -sticky w {*}$opts
    grid $frame.showFrame.diffToRadio -row 3 -column 0 -columnspan 3 \
        -sticky w {*}$opts
    grid $frame.showFrame.diffLabel -row 4 -column 1 -sticky e -pady $::PAD
    grid $frame.showFrame.diffGenSpinbox -row 4 -column 2 -columnspan 2 \
        -sticky w -pady $::PAD
    grid $frame.showFrame.inContextCheck -row 5 -column 1 -columnspan 2 \
        -sticky w {*}$opts
    pack $frame.findFrame -side top -fill x {*}$opts
    grid $frame.findFrame.findLabel -row 0 -column 0 -sticky w {*}$opts
    grid $frame.findFrame.findEntry -row 1 -column 0 -sticky w {*}$opts
    pack $frame.quitButton -side bottom {*}$opts
}

oo::define App method make_tabs {} {
    set Tabs [ttk::notebook .panes.tabs]
    ttk::notebook::enableTraversal $Tabs
    $Tabs add [my make_files_tree] -text Files -underline 0
    $Tabs add [my make_generations_tree] -text Generations -underline 0
    return $Tabs
}

oo::define App method make_files_tree {} {
    set frame [ttk::frame .panes.tabs.filenameTreeFrame]
    set name filenameTree
    set FilenameTree [ttk::treeview $frame.$name -show tree \
        -selectmode browse]
    ui::scrollize $frame $name vertical
    gui_misc::set_tree_tags $FilenameTree
    return $frame
}

oo::define App method make_generations_tree {} {
    set frame [ttk::frame .panes.tabs.generationTreeFrame]
    set name generationTree
    set GenerationTree [ttk::treeview $frame.$name \
        -columns {Created Message}]
    ui::scrollize $frame $name both
    $GenerationTree configure -show tree -selectmode browse
    $GenerationTree column #0 -stretch false
    $GenerationTree column 0 -stretch false
    $GenerationTree column 1 -stretch true
    gui_misc::set_tree_tags $GenerationTree
    return $frame
}

oo::define App method make_status_bar {} {
    if {$StoreFilename ne ""} {
        set message "Read \"$StoreFilename\""
        set ms $::MEDIUM_WAIT
    } else {
        set message "Click Open Store… to choose a store"
        set ms $::LONG_WAIT
    }
    set frame [ttk::frame .statusFrame]
    set StatusInfoLabel [ttk::label $frame.statusInfoLabel -relief sunken \
                         -text $message]
    set StatusAddableLabel [ttk::label $frame.statusAddableLabel \
                            -relief sunken]
    set StatusUpdatableLabel [ttk::label $frame.statusUpdatableLabel \
                              -relief sunken]
    set StatusCleanableLabel [ttk::label $frame.statusCleanableLabel \
                              -relief sunken]
    set StatusSizeLabel [ttk::label $frame.statusSizeLabel -relief sunken]
    pack $frame.statusInfoLabel -side left -fill x -expand true
    pack $frame.statusSizeLabel -side right -fill x
    pack $frame.statusCleanableLabel -side right -fill x
    pack $frame.statusUpdatableLabel -side right -fill x
    pack $frame.statusAddableLabel -side right -fill x
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
    bind . <Escape> [callback on_quit]
    bind . <KP_Enter> [callback on_find]
    bind . <F3> [callback on_find]
    bind . <Alt-a> [callback on_add_addable]
    bind . <Alt-b> [callback on_about]
    bind . <Alt-c> [callback on_copy_to]
    bind . <Alt-d> {.controlsFrame.showFrame.diffWithDiskRadio invoke}
    bind . <Alt-e> [callback on_extract]
    bind . <Alt-i> {.controlsFrame.showFrame.inContextCheck invoke}
    bind . <Alt-l> {.controlsFrame.showFrame.withLinos invoke}
    bind . <Alt-m> {
        tk_popup .controlsFrame.moreButton.menu \
            [expr {[winfo rootx .controlsFrame.moreButton]}] \
            [expr {[winfo rooty .controlsFrame.moreButton] + \
                   [winfo height .controlsFrame.moreButton]}]
    }
    bind . <Alt-n> {focus .controlsFrame.findFrame.findEntry}
    bind . <Alt-o> [callback on_open]
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
