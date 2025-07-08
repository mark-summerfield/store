# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require gui_globals
package require gui_misc
package require ntext 1

oo::class create App {
    variable StoreFilename
    variable FilenameTree
    variable GenerationTree
    variable Text
    variable StatusLabel
}

oo::define App constructor {} {
    set StoreFilename .[file tail [pwd]].str

}

oo::define App method show {} {
    my prepare
    my make_widgets
    my make_layout
    my make_bindings
    my display
}

oo::define App method prepare {} {
    wm withdraw .
    puts "App::prepare TODO load geometry!" ;# TODO delete
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [gui_misc::icon store.svg]
    wm minsize . 260 300
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
    option add *font default
    ttk::style configure TButton -font default
}

oo::define App method display {} {
    wm deiconify .
    raise .
    focus .
}

oo::define App method make_widgets {} {
    set panes [ttk::panedwindow .panes -orient horizontal]
    $panes add [my make_tabs]
    $panes add [my make_text_frame]
    my make_status_label
    my make_buttons
}    

oo::define App method make_buttons {} {
    set buttonFrame [ttk::frame .buttonFrame]
    # TODO more buttons
    set quitButton [ttk::button .buttonFrame.quitButton \
        -text Quit -underline 0 -command [callback on_quit]]
    # TODO layout buttons
    pack .buttonFrame.quitButton -side bottom -padx $::PAD -pady $::PAD
}

oo::define App method make_tabs {} {
    set tabs [ttk::notebook .panes.tabs]
    ttk::notebook::enableTraversal $tabs
    set FilenameTree [ttk::treeview .panes.tabs.filenameTree \
        -striped true]
    set GenerationTree [ttk::treeview .panes.tabs.generationTree \
        -striped true]
    $tabs add $FilenameTree -text Files -underline 0
    $tabs add $GenerationTree -text Generations -underline 0
    return $tabs
}

oo::define App method make_text_frame {} {
    set textFrame [ttk::frame .textFrame]
    set Text [text .textFrame.text -wrap word \
        -yscrollcommand {.textFrame.scrolly set} -font CommitMono]
    bindtags $Text {$Text Ntext . all}
    ttk::scrollbar .textFrame.scrolly -orient vertical \
        -command {.textFrame.text yview}
    pack .textFrame.scrolly -side right -fill y -expand true
    pack .textFrame.text -side left -fill both -expand true
    autoscroll::autoscroll .textFrame.scrolly
    return $textFrame
}

oo::define App method make_status_label {} {
    set StatusLabel [ttk::label .statusLabel -relief sunken\
        -text "Using '$StoreFilename'"]
    after 10_000 [callback set_status ""]
}

oo::define App method make_layout {} {
    grid .panes -column 0 -row 0 -sticky news
    grid .buttonFrame -column 1 -row 0 -sticky ns
    grid .statusLabel -row 1 -columnspan 2 -sticky ew -pady $::PAD
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 0 -weight 1

}

oo::define App method make_bindings {} {
    bind . <Escape> [callback on_quit]
    bind . <Alt-q> [callback on_quit]
    puts "App::make_bindings" ;# TODO
}    

oo::define App method on_quit {} {
    puts "App::on_quit TODO save geometry!" ;# TODO delete
    exit
}

oo::define App method set_status {{text ""}} {
    $StatusLabel configure -text $text
}
