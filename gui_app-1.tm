# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require diff
package require gui_globals
package require gui_misc
package require inifile
package require ntext 1

oo::class create App {
    variable ConfigFilename
    variable Tabs
    variable StoreFilename
    variable FilenameTree
    variable GenerationTree
    variable Text
    variable StatusLabel
}

oo::define App constructor {} {
    set ConfigFilename [misc::get_ini_filename]
    set StoreFilename [file normalize .[file tail [pwd]].str]
    if {![file exists $StoreFilename]} {
        set StoreFilename ""
    }

}

oo::define App method show {} {
    my read_config
    my prepare
    my make_widgets
    my make_layout
    my make_bindings
    my display
}

oo::define App method read_config {} {
    set size [expr {1 + [font configure TkDefaultFont -size]}]
    if {![file exists $ConfigFilename]} {
        font create CommitMono -family CommitMono -size $size
        return
    }
    set ini [ini::open $ConfigFilename -encoding utf-8 r]
    try {
        if {[ini::exists $ini $::SECT_WINDOW]} {
            set geometry [ini::value $ini $::SECT_WINDOW $::KEY_GEOMETRY ""]
            if {$geometry ne ""} {
                wm geometry . $geometry
            }
            set size [ini::value $ini $::SECT_WINDOW $::KEY_FONTSIZE $size]
        }
        font create CommitMono -family CommitMono -size $size
    } finally {
        ::ini::close $ini
    }

}

oo::define App method prepare {} {
    wm withdraw .
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [misc::icon store.svg]
    wm minsize . 260 300
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method display {} {
    set widget .
    if {$StoreFilename ne ""} {
        wm title . "Store — [file dirname $StoreFilename]"
        set widget $FilenameTree
        my populate_file_tree
        my populate_generation_tree
        my on_files_tab
    } else {
        wm title . Store
    }
    wm deiconify .
    raise .
    focus $widget
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
        -text Quit -underline 0 -compound left \
        -image [misc::icon quit.svg $::ICON_SIZE] \
        -command [callback on_quit]]
    # TODO layout buttons
    pack .buttonFrame.quitButton -side bottom -padx $::PAD -pady $::PAD
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
    my set_tree_tags $FilenameTree
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
    my set_tree_tags $GenerationTree
    return $generationTreeFrame
}

oo::define App method set_tree_tags {tree} {
    $tree tag configure parent -foreground blue
    $tree tag configure untracked -foreground red
    $tree tag configure generation -foreground green
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
    if {$StoreFilename ne ""} {
        set message "Read '$StoreFilename'"
        set ms $::MEDIUM_WAIT
    } else {
        set message "Click Open… to choose a store"
        set ms $::LONG_WAIT
    }
    set StatusLabel [ttk::label .statusLabel -relief sunken -text $message]
    after $ms [callback set_status ""]
}

oo::define App method make_layout {} {
    grid .panes -column 0 -row 0 -sticky news
    grid .buttonFrame -column 1 -row 0 -sticky ns
    grid .statusLabel -row 1 -columnspan 2 -sticky ew -pady $::PAD
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 0 -weight 1

}

oo::define App method make_bindings {} {
    bind $Tabs <<NotebookTabChanged>> [callback on_tab_changed]
    bind $FilenameTree <<TreeviewSelect>> [callback on_filename_tree_select]
    bind $GenerationTree <<TreeviewSelect>> \
        [callback on_generation_tree_select]
    bind . <Escape> [callback on_quit]
    bind . <Alt-q> [callback on_quit]
    puts "App::make_bindings" ;# TODO
}    

oo::define App method set_status {{text ""}} {
    $StatusLabel configure -text $text
}

oo::define App method populate_file_tree {} {
    $FilenameTree delete [$FilenameTree children {}]
    set prev_name ""
    set parent {}
    set str [Store new $StoreFilename]
    try {
        foreach {name gid} [$str history {}] {
            if {$name ne $prev_name} {
                set prev_name $name
                set tag [expr {[$str untracked $name] ? "untracked" \
                                                      : "parent"}]
                set parent [$FilenameTree insert {} end -text $name \
                            -tags $tag]
            }
            $FilenameTree insert $parent end -text @$gid -tags generation
        }
    } finally {
        $str close
    }
}

oo::define App method populate_generation_tree {} {
    $GenerationTree delete [$GenerationTree children {}]
    set prev_gid ""
    set parent {}
    set str [Store new $StoreFilename]
    try {
        foreach {gid created message filename} [$str generations true] {
            if {$gid ne $prev_gid} {
                set prev_gid $gid
                set parent [$GenerationTree insert {} end -text @$gid \
                    -tags parent -values [list $created $message]]
            }
            set tag [expr {[$str untracked $filename] ? "untracked" \
                                                      : "generation"}]
            $GenerationTree insert $parent end -text $filename -tags $tag
        }
    } finally {
        $str close
    }
}

oo::define App method show_file {gid filename} {
    set str [Store new $StoreFilename]
    try {
        lassign [$str get $gid $filename] _ data
    } finally {
        $str close
    }
    $Text delete 1.0 end
    $Text insert end [encoding convertfrom -profile replace utf-8 $data]
}

oo::define App method on_tab_changed {} {
    if {[$Tabs index [$Tabs select]]} {
        my on_generations_tab
    } else {
        my on_files_tab
    }
}

oo::define App method on_filename_tree_select {} {
    set item [$FilenameTree selection]
    set gid [$FilenameTree item $item -text]
    set parent [$FilenameTree parent $item]
    set filename [$FilenameTree item $parent -text]
    if {$filename ne "" && $gid ne ""} {
        my show_file [string trimleft $gid @] $filename
    }
}

oo::define App method on_generation_tree_select {} {
    set item [$GenerationTree selection]
    set filename [$GenerationTree item $item -text]
    set parent [$GenerationTree parent $item]
    set gid [$GenerationTree item $parent -text]
    if {$filename ne "" && $gid ne ""} {
        my show_file [string trimleft $gid @] $filename
    }
}

oo::define App method on_files_tab {} {
    focus $FilenameTree
    if {![llength [$FilenameTree selection]]} {
        set first [lindex [$FilenameTree children {}] 0]
        $FilenameTree see $first
        $FilenameTree selection set $first
        $FilenameTree focus $first
    }
}

oo::define App method on_generations_tab {} {
    focus $GenerationTree
    if {![llength [$GenerationTree selection]]} {
        set first [lindex [$GenerationTree children {}] 0]
        $GenerationTree see $first
        $GenerationTree selection set $first
        $GenerationTree focus $first
    }
}

oo::define App method on_quit {} {
    set ini [ini::open $ConfigFilename -encoding utf-8 w]
    try {
        ini::set $ini $::SECT_WINDOW $::KEY_GEOMETRY [wm geometry .]
        ini::set $ini $::SECT_WINDOW $::KEY_FONTSIZE \
            [font configure CommitMono -size]
        ini::commit $ini
    } finally {
        ::ini::close $ini
    }
    exit
}
