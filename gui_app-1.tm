# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require gui_globals
package require gui_misc
package require inifile
package require lambda 1
package require ntext 1

set ShowState asis ;# should be an instance variable!

oo::class create App {
    variable ConfigFilename
    variable Tabs
    variable StoreFilename
    variable FilenameTree
    variable GenerationTree
    variable Text
    variable StatusInfoLabel
    variable StatusAddableLabel
    variable StatusUpdatableLabel
    variable StatusCleanableLabel
    variable StatusSizeLabel
}

oo::define App constructor {configFilename} {
    set ConfigFilename $configFilename
    set StoreFilename [file normalize .[file tail [pwd]].str]
    if {![file exists $StoreFilename]} {
        set StoreFilename ""
    }

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
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [misc::icon store.svg]
    wm minsize . 640 480
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
    after 50 [lambda {} { .panes sashpos 0 [winfo width .controlsFrame] }]
}

oo::define App method make_widgets {} {
    set panes [ttk::panedwindow .panes -orient horizontal]
    $panes add [my make_tabs]
    $panes add [my make_text_frame]
    my make_status_bar
    my make_controls
    my layout_controls
}    

# TODO add tooltips…
oo::define App method make_controls {} {
    set controlsFrame [ttk::frame .controlsFrame]
    ttk::button .controlsFrame.openButton -text {Open Store…} \
        -underline 0 -compound left -command [callback on_open] \
        -image [misc::icon document-open.svg $::ICON_SIZE]
    ttk::button .controlsFrame.addButton -text Add -underline 0 \
        -compound left -command [callback on_add] \
        -image [misc::icon document-save-as.svg $::ICON_SIZE]
    ttk::button .controlsFrame.updateButton -text Update -underline 0 \
        -compound left -command [callback on_update] \
        -image [misc::icon document-save.svg $::ICON_SIZE]
    ttk::button .controlsFrame.extractButton -text Extract -underline 0 \
        -compound left -command [callback on_extract] \
        -image [misc::icon edit-copy.svg $::ICON_SIZE]
    ttk::button .controlsFrame.copyToButton -text {Copy To…} -underline 0 \
        -compound left -command [callback on_copy_to] \
        -image [misc::icon folder-new.svg $::ICON_SIZE]
    ttk::button .controlsFrame.ignoresButton -text Ignores… -underline 0 \
        -compound left -command [callback on_ignores] \
        -image [misc::icon document-properties.svg $::ICON_SIZE]
    ttk::button .controlsFrame.cleanButton -text Clean -underline 1 \
        -compound left -command [callback on_clean] \
        -image [misc::icon edit-clear.svg $::ICON_SIZE]
    ttk::button .controlsFrame.purgeButton -text Purge… -underline 0 \
        -compound left -command [callback on_purge] \
        -image [misc::icon edit-cut.svg $::ICON_SIZE]
    ttk::frame .controlsFrame.showFrame -relief groove 
    ttk::radiobutton .controlsFrame.showFrame.asIsRadio \
        -text "Show As-Is" -underline 0 -value asis -variable ::ShowState \
        -command [callback on_show_asis]
    ttk::radiobutton .controlsFrame.showFrame.diffWithDiskRadio \
        -text "Diff with Disk" -underline 5 -value disk \
        -variable ::ShowState -command [callback on_show_diff_with_disk]
    ttk::radiobutton .controlsFrame.showFrame.diffToRadio \
        -text "Diff to Gen.:" -underline 0 -value generation \
        -variable ::ShowState -command [callback on_show_diff_to]
    ttk::label .controlsFrame.showFrame.diffLabel -text @
    ttk::spinbox .controlsFrame.showFrame.diffGenSpinbox -format %.0f \
        -from 0 -to 99999 -width 5 -command [callback on_show_diff_to]
    .controlsFrame.showFrame.diffGenSpinbox set 0
    ttk::frame .controlsFrame.findFrame -relief groove 
    ttk::label .controlsFrame.findFrame.findLabel -text Find: -underline 2
    ttk::entry .controlsFrame.findFrame.findEntry -width 15
    ttk::button .controlsFrame.optionsButton -text Options… -underline 2 \
        -compound left -command [callback on_options] \
        -image [misc::icon preferences-system.svg $::ICON_SIZE]
    ttk::button .controlsFrame.helpButton -text Help -compound left \
        -command [callback on_help] \
        -image [misc::icon help.svg $::ICON_SIZE]
    ttk::button .controlsFrame.aboutButton -text About -underline 1 \
        -compound left -command [callback on_about] \
        -image [misc::icon about.svg $::ICON_SIZE]
    ttk::button .controlsFrame.quitButton -text Quit -underline 0 \
        -compound left -command [callback on_quit] \
        -image [misc::icon quit.svg $::ICON_SIZE]
}

oo::define App method layout_controls {} {
    set opts "-padx $::PAD -pady $::PAD"
    pack .controlsFrame.openButton -side top {*}$opts
    pack .controlsFrame.addButton -side top {*}$opts
    pack .controlsFrame.updateButton -side top {*}$opts
    pack .controlsFrame.extractButton -side top {*}$opts
    pack .controlsFrame.copyToButton -side top {*}$opts
    pack .controlsFrame.ignoresButton -side top {*}$opts
    pack .controlsFrame.cleanButton -side top {*}$opts
    pack .controlsFrame.purgeButton -side top {*}$opts
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
    pack .controlsFrame.findFrame -side top -fill x {*}$opts
    grid .controlsFrame.findFrame.findLabel -row 0 -column 0 -sticky w \
        {*}$opts
    grid .controlsFrame.findFrame.findEntry -row 1 -column 0 -sticky w \
        {*}$opts
    pack .controlsFrame.optionsButton -side top {*}$opts
    pack .controlsFrame.quitButton -side bottom {*}$opts
    pack .controlsFrame.helpButton -side bottom {*}$opts
    pack .controlsFrame.aboutButton -side bottom {*}$opts
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
        -yscrollcommand {.textFrame.scrolly set} -font Mono]
    bindtags $Text {$Text Ntext . all}
    ttk::scrollbar .textFrame.scrolly -orient vertical \
        -command {.textFrame.text yview}
    pack .textFrame.scrolly -side right -fill y -expand true
    pack .textFrame.text -side left -fill both -expand true
    autoscroll::autoscroll .textFrame.scrolly
    return $textFrame
}

oo::define App method make_status_bar {} {
    if {$StoreFilename ne ""} {
        set message "Read '$StoreFilename'"
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
    bind . <Escape> [callback on_quit]
    bind . <KP_Enter> [callback on_find]
    bind . <F1> [callback on_help]
    bind . <F3> [callback on_find]
    bind . <Alt-a> [callback on_add]
    bind . <Alt-b> [callback on_about]
    bind . <Alt-c> [callback on_copy_to]
    bind . <Alt-d> {
        .controlsFrame.showFrame.diffToRadio invoke
        focus .controlsFrame.showFrame.diffGenSpinbox
    }
    bind . <Alt-e> [callback on_extract]
    bind . <Alt-i> [callback on_ignores]
    bind . <Alt-l> [callback on_clean]
    bind . <Alt-n> {focus .controlsFrame.findFrame.findEntry}
    bind . <Alt-o> [callback on_open]
    bind . <Alt-p> [callback on_purge]
    bind . <Alt-q> [callback on_quit]
    bind . <Alt-s> {.controlsFrame.showFrame.asIsRadio invoke}
    bind . <Alt-t> [callback on_options]
    bind . <Alt-u> [callback on_update]
    bind . <Alt-w> {.controlsFrame.showFrame.diffWithDiskRadio invoke}
}    

oo::define App method set_status_info {{text ""} {timeout 0}} {
    $StatusInfoLabel configure -text $text
    if {$text ne "" && $timeout > 0} {
        after $timeout [callback set_status_info]
    }
}

# Subtle difference "addable" vs. "to update" is deliberate
oo::define App method report_status {} {
    if {[file exists $StoreFilename]} {
        catch { ;# if the timeout coincides with other db action we skip
            set str [Store new $StoreFilename]
            try {
                set names [$str addable]
                if {[llength $names]} {
                    lassign [misc::n_s [llength $names]] n s
                    $StatusAddableLabel configure -text "$n addable" \
                        -foreground red
                } else {
                    $StatusAddableLabel configure -text "none to add" \
                        -foreground green
                }
                set names [$str updatable]
                if {[llength $names]} {
                    lassign [misc::n_s [llength $names]] n s
                    $StatusUpdatableLabel configure -text "$n to update" \
                        -foreground red
                } else {
                    $StatusUpdatableLabel configure -text "none to update" \
                        -foreground green
                }
                if {[$str needs_clean]} {
                    $StatusCleanableLabel configure -text "cleanable" \
                        -foreground red
                } else {
                    $StatusCleanableLabel configure -text "clean" \
                        -foreground green
                }
            } finally {
                $str close
            }
            $StatusSizeLabel configure -text [misc::human_size \
                                                [file size $StoreFilename]]
        }
    } else {
        $StatusSizeLabel configure -text ""
    }
    after $::STATUS_WAIT [callback report_status]
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

oo::define App method get_selected {} {
    set ok false
    if {[$Tabs  select] eq ".panes.tabs.filenameTreeFrame"} {
        set item [$FilenameTree selection]
        set txt [$FilenameTree item $item -text]
        if {[string match {@*} $txt]} {
            set gid [string range $txt 1 end]
            set filename [$FilenameTree item [$FilenameTree parent $item] \
                    -text]
        } else {
            set gid 0
            set filename $txt
        }
        set ok true
    } else {
        set item [$GenerationTree selection]
        set txt [$GenerationTree item $item -text]
        if {[string match {@*} $txt]} {
            set gid [string range $txt 1 end]
            set filename "" ;# no filename specified
        } else {
            set gid [$GenerationTree item [$GenerationTree parent $item] \
                    -text]
            set gid [string range $gid 1 end]
            set filename $txt
            set ok true
        }
    }
    return [list $ok $gid $filename]
}

oo::define App method diff {new_gid old_gid filename} {
    puts "TODO diff: @$new_gid vs @$old_gid '$filename'" ;# TODO
}

oo::define App method on_open {} {
    puts "TODO on_open" ;# TODO
}

oo::define App method on_add {} {
    puts "TODO on_add" ;# TODO
}

oo::define App method on_update {} {
    puts "TODO on_update" ;# TODO
}

oo::define App method on_extract {} {
    puts "TODO on_extract" ;# TODO
}

oo::define App method on_copy_to {} {
    puts "TODO on_copy_to" ;# TODO
}

oo::define App method on_ignores {} {
    puts "TODO on_ignores" ;# TODO
}

oo::define App method on_clean {} {
    puts "TODO on_clean" ;# TODO
}

oo::define App method on_purge {} {
    puts "TODO on_purge" ;# TODO prompt yes/no first!
}

oo::define App method on_show_asis {} {
    puts "TODO on_show_asis" ;# TODO
}

oo::define App method on_show_diff_with_disk {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to diff against" $::SHORT_WAIT
    } else {
        my diff $gid $gid $filename
    }
}

oo::define App method on_show_diff_to {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to diff against" $::SHORT_WAIT
    } else {
        set gid2 [.controlsFrame.showFrame.diffGenSpinbox get]
        if {$gid && $gid2 > $gid} {
            set t $gid
            set gid $gid2
            set gid2 $t
        }
        my diff $gid $gid2 $filename
    }
}

oo::define App method on_find {} {
    puts "TODO on_find" ;# TODO
}

oo::define App method on_options {} {
    puts "TODO on_options" ;# TODO
}

oo::define App method on_help {} {
    puts "TODO on_help" ;# TODO
}

oo::define App method on_about {} {
    puts "TODO on_about" ;# TODO
}

oo::define App method on_quit {} {
    set ini [ini::open $ConfigFilename -encoding utf-8 w]
    try {
        ini::set $ini $::SECT_WINDOW $::KEY_GEOMETRY [wm geometry .]
        ini::set $ini $::SECT_WINDOW $::KEY_FONTSIZE \
            [font configure Mono -size]
        ini::set $ini $::SECT_WINDOW $::KEY_FONTFAMILY \
            [font configure Mono -family]
        ini::commit $ini
    } finally {
        ::ini::close $ini
    }
    exit
}
