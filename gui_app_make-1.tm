# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require gui_misc

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
    set controlsFrame [ttk::frame .controlsFrame]
    ttk::button .controlsFrame.openButton -text "Open Store…" \
        -underline 0 -compound left -command [callback on_open] \
        -image [form::icon document-open.svg $::ICON_SIZE]
    ttk::button .controlsFrame.addButton -text "Add Addable…" -underline 0 \
        -compound left -command [callback on_add_addable] \
        -image [form::icon document-save-as.svg $::ICON_SIZE]
    ttk::button .controlsFrame.updateButton -text Update -underline 0 \
        -compound left -command [callback on_update] \
        -image [form::icon document-save.svg $::ICON_SIZE]
    ttk::button .controlsFrame.extractButton -text Extract -underline 0 \
        -compound left -command [callback on_extract] \
        -image [form::icon edit-copy.svg $::ICON_SIZE]
    ttk::button .controlsFrame.copyToButton -text "Copy To…" -underline 0 \
        -compound left -command [callback on_copy_to] \
        -image [form::icon folder-new.svg $::ICON_SIZE]
    ttk::menubutton .controlsFrame.moreButton -text More -underline 0
    menu .controlsFrame.moreButton.menu
    .controlsFrame.moreButton.menu add command -label Tags… \
        -underline 0 -compound left -command [callback on_tags] \
        -image [form::icon bookmark-new.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add command -label Ignores… \
        -underline 0 -compound left -command [callback on_ignores] \
        -image [form::icon document-properties.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add separator
    .controlsFrame.moreButton.menu add command -label "Add File…" \
        -underline 0 -compound left -command [callback on_add_file] \
        -image [form::icon document-new.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add separator
    .controlsFrame.moreButton.menu add command -label Restore… \
        -underline 0 -compound left -command [callback on_restore] \
        -image [form::icon edit-undo.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add command -label Clean -underline 0 \
        -compound left -command [callback on_clean] \
        -image [form::icon edit-clear.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add command -label Purge… -underline 0 \
        -compound left -command [callback on_purge] \
        -image [form::icon edit-cut.svg $::ICON_SIZE]
    .controlsFrame.moreButton.menu add separator
    .controlsFrame.moreButton.menu add command -label About -underline 1 \
        -compound left -command [callback on_about] \
        -image [form::icon about.svg $::ICON_SIZE]
    .controlsFrame.moreButton configure -menu .controlsFrame.moreButton.menu
    ttk::frame .controlsFrame.showFrame -relief groove 
    ttk::radiobutton .controlsFrame.showFrame.asIsRadio \
        -text "Show As-Is" -underline 0 -value asis \
        -variable [my varname ShowState] -command [callback on_show_asis]
    ttk::radiobutton .controlsFrame.showFrame.diffWithDiskRadio \
        -text "Diff with Disk" -underline 0 -value disk \
        -variable [my varname ShowState] \
        -command [callback on_show_diff_with_disk]
    ttk::radiobutton .controlsFrame.showFrame.diffToRadio \
        -text "Diff to Gen.:" -underline 5 -value generation \
        -variable [my varname ShowState] -command [callback on_show_diff_to]
    ttk::checkbutton .controlsFrame.showFrame.inContextCheck \
        -text "In Context" -underline 0 -onvalue true -offvalue false \
        -variable [my varname InContext] -command [callback on_in_context]
    ttk::label .controlsFrame.showFrame.diffLabel -text @
    ttk::spinbox .controlsFrame.showFrame.diffGenSpinbox -format %.0f \
        -from 0 -to 99999 -width 5 -command [callback on_show_diff_to]
    .controlsFrame.showFrame.diffGenSpinbox set 0
    ttk::frame .controlsFrame.findFrame -relief groove 
    ttk::label .controlsFrame.findFrame.findLabel -text Find: -underline 2
    set FindEntry [ttk::entry .controlsFrame.findFrame.findEntry -width 15]
    ttk::button .controlsFrame.quitButton -text Quit -underline 0 \
        -compound left -command [callback on_quit] \
        -image [form::icon quit.svg $::ICON_SIZE]
}

oo::define App method layout_controls {} {
    set opts "-padx $::PAD -pady $::PAD"
    pack .controlsFrame.openButton -side top {*}$opts
    pack .controlsFrame.addButton -side top {*}$opts
    pack .controlsFrame.updateButton -side top {*}$opts
    pack .controlsFrame.extractButton -side top {*}$opts
    pack .controlsFrame.copyToButton -side top {*}$opts
    pack .controlsFrame.moreButton -side top -ipadx [expr {$::PAD * 2}] \
        {*}$opts
    pack .controlsFrame.showFrame -side top -fill x {*}$opts
    grid .controlsFrame.showFrame.asIsRadio -row 0 -column 0 -columnspan 2 \
        -sticky w {*}$opts
    grid .controlsFrame.showFrame.diffWithDiskRadio -row 1 -column 0 \
        -columnspan 2 -sticky w {*}$opts
    grid .controlsFrame.showFrame.diffToRadio -row 2 -column 0 \
        -columnspan 2 -sticky w {*}$opts
    grid .controlsFrame.showFrame.diffLabel -row 3 -column 0 -sticky e \
        -pady [expr {2 * $::PAD}]
    grid .controlsFrame.showFrame.diffGenSpinbox -row 3 -column 1 \
        -sticky w -pady [expr {2 * $::PAD}]
    grid .controlsFrame.showFrame.inContextCheck -row 4 -column 0 \
        -columnspan 2 -sticky w {*}$opts
    pack .controlsFrame.findFrame -side top -fill x {*}$opts
    grid .controlsFrame.findFrame.findLabel -row 0 -column 0 -sticky w \
        {*}$opts
    grid .controlsFrame.findFrame.findEntry -row 1 -column 0 -sticky w \
        {*}$opts
    pack .controlsFrame.quitButton -side bottom {*}$opts
}

oo::define App method make_tabs {} {
    set Tabs [ttk::notebook .panes.tabs]
    ttk::notebook::enableTraversal $Tabs
    $Tabs add [my make_files_tree] -text Files -underline 0
    $Tabs add [my make_generations_tree] -text Generations -underline 0
    return $Tabs
}

oo::define App method make_files_tree {} {
    set filenameTreeFrame [ttk::frame .panes.tabs.filenameTreeFrame]
    set FilenameTree [ttk::treeview \
        .panes.tabs.filenameTreeFrame.filenameTree \
        -yscrollcommand {.panes.tabs.filenameTreeFrame.scrolly set}]
    $FilenameTree configure -show tree -selectmode browse
    ttk::scrollbar .panes.tabs.filenameTreeFrame.scrolly -orient vertical \
        -command {.panes.tabs.filenameTreeFrame.filenameTree yview}
    gui_misc::set_tree_tags $FilenameTree
    grid .panes.tabs.filenameTreeFrame.filenameTree -row 0 -column 0 \
        -sticky news
    grid .panes.tabs.filenameTreeFrame.scrolly -row 0 -column 1 -sticky ns
    grid columnconfigure .panes.tabs.filenameTreeFrame 0 -weight 9
    grid rowconfigure .panes.tabs.filenameTreeFrame 0 -weight 1
    autoscroll::autoscroll .panes.tabs.filenameTreeFrame.scrolly
    return $filenameTreeFrame
}

oo::define App method make_generations_tree {} {
    set generationTreeFrame [ttk::frame .panes.tabs.generationTreeFrame]
    set GenerationTree [ttk::treeview \
        .panes.tabs.generationTreeFrame.generationTree \
        -columns {Created Message} \
        -yscrollcommand {.panes.tabs.generationTreeFrame.scrolly set} \
        -xscrollcommand {.panes.tabs.generationTreeFrame.scrollx set}]
    $GenerationTree configure -show tree -selectmode browse
    $GenerationTree column #0 -stretch false
    $GenerationTree column 0 -stretch false
    $GenerationTree column 1 -stretch true
    ttk::scrollbar .panes.tabs.generationTreeFrame.scrolly \
        -orient vertical \
        -command {.panes.tabs.generationTreeFrame.generationTree yview}
    ttk::scrollbar .panes.tabs.generationTreeFrame.scrollx \
        -orient horizontal \
        -command {.panes.tabs.generationTreeFrame.generationTree xview}
    grid .panes.tabs.generationTreeFrame.generationTree -row 0 -column 0 \
        -sticky news
    grid .panes.tabs.generationTreeFrame.scrolly -row 0 -column 1 \
        -sticky ns
    grid .panes.tabs.generationTreeFrame.scrollx -row 1 -column 0 \
        -sticky we
    grid columnconfigure .panes.tabs.generationTreeFrame 0 -weight 9
    grid rowconfigure .panes.tabs.generationTreeFrame 0 -weight 1
    autoscroll::autoscroll .panes.tabs.generationTreeFrame.scrolly
    autoscroll::autoscroll .panes.tabs.generationTreeFrame.scrollx
    gui_misc::set_tree_tags $GenerationTree
    return $generationTreeFrame
}

oo::define App method make_status_bar {} {
    if {$StoreFilename ne ""} {
        set message "Read \"$StoreFilename\""
        set ms $::MEDIUM_WAIT
    } else {
        set message "Click Open Store… to choose a store"
        set ms $::LONG_WAIT
    }
    set statusFrame [ttk::frame .statusFrame]
    set StatusInfoLabel [ttk::label .statusFrame.statusInfoLabel \
                         -relief sunken -text $message]
    set StatusAddableLabel [ttk::label .statusFrame.statusAddableLabel \
                            -relief sunken]
    set StatusUpdatableLabel [ttk::label .statusFrame.statusUpdatableLabel \
                              -relief sunken]
    set StatusCleanableLabel [ttk::label .statusFrame.statusCleanableLabel \
                              -relief sunken]
    set StatusSizeLabel [ttk::label .statusFrame.statusSizeLabel \
                         -relief sunken]
    pack .statusFrame.statusInfoLabel -side left -fill x -expand true
    pack .statusFrame.statusSizeLabel -side right -fill x
    pack .statusFrame.statusCleanableLabel -side right -fill x
    pack .statusFrame.statusUpdatableLabel -side right -fill x
    pack .statusFrame.statusAddableLabel -side right -fill x
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
