# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config_form
package require fileutil 1
package require gui_actions
package require gui_add_form
package require gui_ignores_form
package require gui_tags_form
package require ref
package require util
package require yes_no_form

oo::define App method on_tab_changed {} {
    if {[$Tabs index [$Tabs select]]} {
        my on_generations_tab
    } else {
        my on_files_tab
    }
}

oo::define App method on_filename_tree_select {} {
    set item [$FilenameTree selection]
    if {$item ne ""} {
        set gid [$FilenameTree item $item -text]
        set parent [$FilenameTree parent $item]
        set filename [$FilenameTree item $parent -text]
        lassign [my get_selected] ok gid filename
        if {$ok} {
            my show_file $gid $filename
        }
    }
}

oo::define App method on_generation_tree_select {} {
    set item [$GenerationTree selection]
    if {$item ne ""} {
        set filename [$GenerationTree item $item -text]
        set parent [$GenerationTree parent $item]
        set gid [$GenerationTree item $parent -text]
        lassign [my get_selected] ok gid filename
        if {$ok} {
            my show_file $gid $filename
        }
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

oo::define App method on_open {} {
    set dirname [tk_chooseDirectory -initialdir . \
                 -title "[tk appname] — Choose Store Folder to Open" \
                 -mustexist 1 -parent .]
    if {$dirname ne ""} {
        cd $dirname
        set StoreFilename [file normalize .[file tail $dirname].str]
        wm title . "Store — [file dirname $StoreFilename]"
        my populate
        my set_status_info "Read \"$StoreFilename\""
        my report_status
        my jump_to_first
        my update_ui
    }
}

oo::define App method on_add_files {} {
    set filenames [tk_getOpenFile -initialdir . -multiple 1 \
                   -title "[tk appname] — Choose a File to Add" -parent .]
    set n [llength $filenames] 
    if {$n} {
        set str [Store new $StoreFilename [callback set_status_info]]
        try {
            $str add {*}$filenames
            if {$n == 1} {
                my set_status_info "added $filenames" $::SHORT_WAIT
            } else {
                my set_status_info "added $n files" $::SHORT_WAIT
            }
            my report_status
            my populate
        } finally {
            $str destroy
        }
    }
}

oo::define App method on_add_addable {} {
    set names [list]
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        set names [$str addable]
    } finally {
        $str destroy
    }
    if {[llength $names]} {
        set form [AddForm new]
        $form show $StoreFilename [callback refresh] $names
    } else {
        my set_status_info "none to add" $::SHORT_WAIT
    }
}

oo::define App method on_update {} {
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        if {[$str have_updates]} {
            $str update ""
            my set_status_info updated $::SHORT_WAIT
            my report_status
            my populate
        } else {
            my set_status_info "none to update" $::SHORT_WAIT
        }
    } finally {
        $str destroy
    }
}

oo::define App method on_extract {} {
    lassign [my get_selected] ok gid filename
    if {$ok} {
        set str [Store new $StoreFilename [callback set_status_info]]
        try {
            $str extract $gid $filename
        } finally {
            $str destroy
        }
    } else {
        my set_status_info "no file selected for extraction" $::SHORT_WAIT
    }
}

oo::define App method on_copy_to {} {
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        set gid [$str current_generation]
        if {$gid} {
            set dirname [tk_chooseDirectory -initialdir . \
                         -title "[tk appname] — Choose Folder to Copy To" \
                         -mustexist 0 -parent .]
            if {$dirname ne ""} {
                $str copy $gid $dirname
                my set_status_info "copied @$gid to $dirname" $::SHORT_WAIT
            }
        } else {
            my set_status_info "no generation to copy" $::SHORT_WAIT
        }
    } finally {
        $str destroy
    }
}

oo::define App method on_tags {} {
    set form [TagsForm new]
    $form show $StoreFilename [callback refresh]
}

oo::define App method on_ignores {} {
    set form [IgnoresForm new]
    $form show $StoreFilename [callback report_status]
}

oo::define App method on_clean {} {
    set str [Store new $StoreFilename [callback set_status_info]]
    try {
        $str clean
        my set_status_info cleaned $::SHORT_WAIT
        my report_status
    } finally {
        $str destroy
    }
}

oo::define App method on_restore {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to restore" $::SHORT_WAIT
    } else {
        if {[YesNoForm show "[tk appname] — Restore" \
                "Restore \"$filename\" from the Store\noverwriting the\
                disk version?\nThis cannot be undone!" no] eq "yes"} {
            set str [Store new $StoreFilename [callback set_status_info]]
            try {
                set n [$str restore $filename]
                my set_status_info "restored $filename" $::SHORT_WAIT
                my report_status
                my populate
            } finally {
                $str destroy
            }
        }
    }
}

oo::define App method on_purge {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to purge" $::SHORT_WAIT
    } else {
        if {[YesNoForm show "[tk appname] — Purge" \
                "Permanently delete \"$filename\" from the Store?\n
                This cannot be undone!" no] eq "yes"} {
            set str [Store new $StoreFilename [callback set_status_info]]
            try {
                set n [$str purge $filename]
                lassign [util::n_s $n] n s
                my set_status_info "purged $n version$s" $::SHORT_WAIT
                my report_status
                my populate
            } finally {
                $str destroy
            }
        }
    }
}

oo::define App method on_show_asis {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to show" $::SHORT_WAIT
    } else {
        my update_ui
        my show_file $gid $filename
    }
}

oo::define App method on_show_diff_with_disk {} {
    lassign [my get_selected] ok gid filename
    if {!$ok} {
        my set_status_info "Select a file to diff against" $::SHORT_WAIT
    } else {
        my update_ui
        my diff 0 $gid $filename
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
        my update_ui
        my diff $gid $gid2 $filename
    }
}

oo::define App method on_show_options {} {
    set frame .controlsFrame
    if {$ShowOptions} {
        set opts "-padx $::PAD -pady $::PAD"
        pack forget $frame.findFrame
        pack $frame.showFrame -side top -fill x {*}$opts
        pack $frame.findFrame -side top -fill x {*}$opts
    } else {
        pack forget $frame.showFrame
    }
}

oo::define App method on_show_all {} {
    if {$ShowState eq "asis"} {
        if {$ShowAll} {
            foreach item [$FilenameTree children {}] {
                $FilenameTree item $item -hidden 0
            }
        } else {
            foreach item [$FilenameTree children {}] {
                set shown [expr {![$FilenameTree tag has updatable $item]}]
                $FilenameTree item $item -hidden $shown
            }
        }
    }
}

oo::define App method on_with_linos {} {
    if {$ShowState eq "asis"} {
        $Text configure -linemap $WithLinos
    }
}

oo::define App method on_in_context {} {
    if {$ShowState eq "disk"} {
        my on_show_diff_with_disk
    } elseif {$ShowState eq "generation"} {
        my on_show_diff_to
    } ;# ignore asis
}

oo::define App method on_find {} {
    set what [$FindEntry get]
    set offset [string length $what]
    if {$offset} {
        set pos [$Text search -nocase $what \
                    "[$Text index insert] + 1 chars"]
        if {$pos eq ""} {
            my set_status_info "no (more) \"$what\" found" $::SHORT_WAIT
        } else {
            $Text mark set insert $pos
            set indexes [$Text tag ranges sel]
            if {$indexes ne ""} { $Text tag remove sel {*}$indexes }
            $Text tag add sel $pos "$pos + $offset chars"
            $Text see $pos
            set lino [expr {int($pos)}]
            my set_status_info "found \"$what\" on line $lino" $::SHORT_WAIT
        }
    } else {
        focus $FindEntry
        my set_status_info "nothing to find" $::SHORT_WAIT
    }
}

oo::define App method on_config {} {
    set ok [Ref new 0]
    set config [Config new]
    set fontfamily [$config fontfamily]
    set fontsize [$config fontsize]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
    if {[$ok get]} {
        if {$fontfamily ne [$config fontfamily] || \
                $fontsize != [$config fontsize]} {
            gui::make_fonts [$config fontfamily] [$config fontsize]
        }
    }
}

oo::define App method on_about {} {
    set ::VERSION ""
    if {$StoreFilename ne ""} {
        set str [Store new $StoreFilename [callback set_status_info]]
        try {
            set ::VERSION [$str version]
        } finally {
            $str destroy
        }
    }
    AboutForm new "An easy-to-use alternative to a version control system" \
        https://github.com/mark-summerfield/store
}

oo::define App method on_quit {} {
    set config [Config new]
    $config save
    exit
}
