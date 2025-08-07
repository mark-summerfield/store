# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require gui_actions
package require lambda 1
package require ui

oo::class create App {
    variable ShowState
    variable WithLinos
    variable InContext
    variable ConfigFilename
    variable StoreFilename
    variable Tabs
    variable FilenameTree
    variable GenerationTree
    variable Text
    variable FindEntry
    variable StatusInfoLabel
    variable StatusAddableLabel
    variable StatusUpdatableLabel
    variable StatusCleanableLabel
    variable StatusSizeLabel
}

oo::define App constructor {configFilename} {
    set ShowState asis
    set WithLinos true
    set InContext true
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
    wm iconphoto . -default [ui::icon store.svg]
    wm minsize . 640 480
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method display {} {
    set widget .
    if {$StoreFilename ne ""} {
        wm title . "Store — [file dirname $StoreFilename]"
        set widget $FilenameTree
        my populate
        my jump_to_first
    } else {
        wm title . Store
    }
    my update_ui
    wm deiconify .
    focus $widget
    raise .
    update
    after idle {.panes sashpos 0 [winfo width .controlsFrame]}
}

oo::define App method update_ui {} {
    const disabled [expr {$StoreFilename eq "" ? "disabled" : "!disabled"}]
    const frame .controlsFrame
    puts "ShowState=$ShowState"
    foreach widget [list $frame.addButton $frame.updateButton \
            $frame.extractButton $frame.copyToButton \
            $frame.showFrame.asIsRadio $frame.showFrame.diffWithDiskRadio \
            $frame.showFrame.diffToRadio $frame.findFrame.findLabel \
            $FindEntry] {
        $widget state $disabled
    }
    if {$ShowState eq "asis"} {
        $frame.showFrame.withLinos state !disabled
        $frame.showFrame.inContextCheck state disabled
        $frame.showFrame.diffLabel state disabled
        $frame.showFrame.diffGenSpinbox state disabled
    } else {
        $frame.showFrame.withLinos state disabled
        $frame.showFrame.inContextCheck state !disabled
        $frame.showFrame.diffLabel state !disabled
        $frame.showFrame.diffGenSpinbox state !disabled
    }
    const state [expr {$StoreFilename eq "" ? "disabled" : "normal"}]
    foreach i {0 1 3 5 6 7} {
        $frame.moreButton.menu entryconfigure $i -state $state
    }
}

oo::define App method refresh {} {
    my populate
    my report_status
}

oo::define App method populate {} {
    my populate_file_tree
    my populate_generation_tree
    my on_files_tab
    if {$StoreFilename ne ""} {
        set str [Store new $StoreFilename [callback set_status_info]]
        try {
            .controlsFrame.showFrame.diffGenSpinbox set \
                [$str current_generation]
        } finally {
            $str destroy
        }
    }
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
            set str [Store new $StoreFilename [callback set_status_info]]
            try {
                set names [$str addable]
                if {[llength $names]} {
                    lassign [ui::n_s [llength $names]] n s
                    $StatusAddableLabel configure -text "$n addable" \
                        -foreground red
                } else {
                    $StatusAddableLabel configure -text "none to add" \
                        -foreground green
                }
                set names [$str updatable]
                if {[llength $names]} {
                    lassign [ui::n_s [llength $names]] n s
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
                $str destroy
            }
            $StatusSizeLabel configure -background "" \
                -text [ui::human_size [file size $StoreFilename]]
        }
    } else {
        $StatusSizeLabel configure -text "" -background orange
    }
    after $::STATUS_WAIT [callback report_status]
}

oo::define App method populate_file_tree {} {
    lassign [my get_selected_from_files] sel_gid sel_filename
    $FilenameTree delete [$FilenameTree children {}]
    set prev_name ""
    set parent {}
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        set updatable [$str updatable]
        foreach {name gid} [$str history {}] {
            if {$name ne $prev_name} {
                set prev_name $name
                if {[lsearch -exact $updatable $name] != -1} {
                    set tag updatable
                } else {
                    set tag [expr {[$str untracked $name] ? "untracked" \
                                                          : "parent"}]
                }
                set parent [$FilenameTree insert {} end -text $name \
                            -tags $tag]
            }
            $FilenameTree insert $parent end -text @$gid -tags generation
        }
        my select_files_tree_item $sel_gid $sel_filename
    } finally {
        $str destroy
    }
}

oo::define App method populate_generation_tree {} {
    lassign [my get_selected_from_generations] ok sel_gid sel_filename
    $GenerationTree delete [$GenerationTree children {}]
    set prev_gid ""
    set parent {}
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        set updatable [$str updatable]
        foreach {gid created message filename} [$str generations true] {
            if {$gid ne $prev_gid} {
                set prev_gid $gid
                set parent [$GenerationTree insert {} end -text @$gid \
                    -tags parent -values [list $created $message]]
            }
            if {[lsearch -exact $updatable $filename] != -1} {
                set tag updatable
            } else {
                set tag [expr {[$str untracked $filename] \
                                ? "untracked" : "generation"}]
            }
            $GenerationTree insert $parent end -text $filename -tags $tag
        }
        if {$ok} { my select_generations_tree_item $sel_gid $sel_filename }
    } finally {
        $str destroy
    }
}

oo::define App method jump_to_first {} {
    foreach item [$FilenameTree children {}] {
        if {[$FilenameTree tag has updatable $item]} {
            $FilenameTree selection set $item
            $FilenameTree see $item
            break
        }
    }
}

oo::define App method show_file {gid filename} {
    if {$ShowState ne "asis"} { 
        set ShowState asis
    }
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        if {!$gid} { set gid [$str current_generation] }
        lassign [$str get $gid $filename] _ data
    } finally {
        $str destroy
    }
    $Text configure -linemap $WithLinos -highlight true
    $Text delete 1.0 end
    $Text insert end [encoding convertfrom -profile replace utf-8 $data]
}

oo::define App method get_selected {} {
    set ok false
    if {[$Tabs  select] eq ".panes.tabs.filenameTreeFrame"} {
        lassign [my get_selected_from_files] ok gid filename
    } else {
        lassign [my get_selected_from_generations] ok gid filename
    }
    return [list $ok $gid $filename]
}

oo::define App method get_selected_from_files {} {
    set item [$FilenameTree selection]
    if {$item eq ""} { return [list false] }
    set txt [$FilenameTree item $item -text]
    if {[string match {@*} $txt]} {
        set gid [string range $txt 1 end]
        set filename [$FilenameTree item [$FilenameTree parent $item] -text]
    } else {
        set gid 0
        set filename $txt
    }
    return [list true $gid $filename]
}

oo::define App method get_selected_from_generations {} {
    set ok false
    set item [$GenerationTree selection]
    if {$item eq ""} { return [list false] }
    set txt [$GenerationTree item $item -text]
    if {[string match {@*} $txt]} {
        set gid [string range $txt 1 end]
        set filename "" ;# no filename specified
    } else {
        set gid [$GenerationTree item [$GenerationTree parent $item] -text]
        set gid [string range $gid 1 end]
        set filename $txt
        set ok true
    }
    return [list $ok $gid $filename]
}

oo::define App method select_files_tree_item {gid filename} {
    foreach item [$FilenameTree children {}] {
        set txt [$FilenameTree item $item -text]
        if {$txt eq $filename} {
            foreach child [$FilenameTree children $item] {
                set txt [$FilenameTree item $child -text]
                if {$txt eq "@$gid"} {
                    set item $child
                    break
                }
            }
            $FilenameTree selection set $item
            $FilenameTree see $item
        }
    }
}

oo::define App method select_generations_tree_item {gid filename} {
    foreach item [$GenerationTree children {}] {
        set txt [$GenerationTree item $item -text]
        if {$txt eq "@$gid"} {
            foreach child [$GenerationTree children $item] {
                set txt [$GenerationTree item $child -text]
                if {$txt eq $filename} {
                    set item $child
                    break
                }
            }
            $GenerationTree selection set $item
            $GenerationTree see $item
        }
    }
}

oo::define App method diff {new_gid old_gid filename} {
    $Text configure -linemap false -highlight false
    gui_actions::diff $StoreFilename $Text $InContext \
        [callback set_status_info] $new_gid $old_gid $filename
}
