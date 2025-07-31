# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_misc
package require diff
package require misc
package require store

namespace eval cli_actions {}

proc cli_actions::add {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        if {$rest eq ""} {
            set names [$str addable]
        } else {
            set names [$str candidates_from_given $rest]
        }
        if {[llength $names]} {
            $str add {*}$names
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::update {reporter storefile rest} {
    set message [join $rest " "]
    set str [Store new $storefile $reporter]
    try {
        if {[$str have_updates]} {
            $str update $message
        } elseif {$::VERBOSE > 1} {
            cli_misc::info "no updates needed"
        }
        set names [$str addable]
        if {$::VERBOSE && [llength $names]} {
            lassign [misc::n_s [llength $names]] n s
            cli_misc::info "$n unstored unignored nonempty file$s present" \
                true
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::extract {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str extract $gid {*}$rest
    } finally {
        $str destroy
    }
}

proc cli_actions::status {reporter storefile rest} {
    set yes_messages [list]
    set no_messages [list]
    set str [Store new $storefile $reporter]
    try {
        set names [$str addable]
        if {[llength $names]} {
            lassign [misc::n_s [llength $names]] n s
            lappend yes_messages "$n unstored unignored nonempty file$s\
                                  present"
            if {$::VERBOSE > 1} {
                lappend yes_messages \
                    {*}[lmap name $names {expr {"  $name"}}]
            }
        } elseif {$::VERBOSE} {
            lappend no_messages "no files to add"
        }
        set names [$str updatable]
        if {[llength $names]} {
            lassign [misc::n_s [llength $names]] n s
            lappend yes_messages "$n file$s to update"
            if {$::VERBOSE > 1} {
                lappend yes_messages \
                    {*}[lmap name $names {expr {"  $name"}}]
            }
        } elseif {$::VERBOSE} {
            lappend no_messages "no updates needed"
        }
        if {$::VERBOSE && [$str needs_clean]} {
            lappend yes_messages "clean needed"
        } elseif {$::VERBOSE} {
            lappend no_messages "no clean needed"
        }
        if {[llength $yes_messages]} {
            cli_misc::info [join $yes_messages "\n"] true
        }
        if {$::VERBOSE && [llength $no_messages]} {
            cli_misc::info [join $no_messages " • "]
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::copy {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str dirname
    try {
        $str copy $gid $dirname
    } on error {message} {
        cli_misc::warn $message
    } finally {
        $str destroy
    }
}

proc cli_actions::print {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str filename
    try {
        lassign [$str get $gid $filename] gid data
        if {$data ne ""} {
            puts -nonewline [encoding convertfrom -profile replace utf-8 \
                             $data]
        } else {
            set gid [$str find_data_gid [$str current_generation] $filename]
            if {$gid} {
                cli_misc::info "\"$filename\" was last updated in @$gid"
            } else {
                set gid [$str find_gid_for_untracked $filename]
                if {$gid} {
                    cli_misc::info "\"$filename\" is not being tracked but\
                        is available in @$gid"
                } else {
                    cli_misc::info "\"$filename\" is not in the store"
                }
            }
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::diff {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] old_gid str rest
    try {
        lassign [GidAndRest $str $rest] new_gid filename
        if {$old_gid == $new_gid} { ;# compare with file
            if {![file exists $filename]} {
                cli_misc::warn "can't diff \"$filename\" @$old_gid not \
                    found in on disk"
            }
            lassign [$str get $old_gid $filename] old_gid old_data
            if {$old_data eq ""} {
                cli_misc::warn "\"$filename\" @$old_gid not found in\
                    the store"
            }
            set new_data [readFile $filename binary]
            set message "\"$filename\" @$old_gid with file on disk"
        } else { ;# compare in store
            set orig_old_gid $old_gid
            set orig_new_gid $new_gid
            if {$old_gid < $new_gid} {
                lassign "$old_gid $new_gid" new_gid old_gid
            }
            lassign [$str get $old_gid $filename] old_gid old_data
            if {!$old_gid} {
                cli_misc::warn "\"$filename\" not in current generation"
            }
            if {$old_data eq ""} {
                WarnFileNotFound $str $orig_old_gid $filename
            }
            lassign [$str get $new_gid $filename] new_gid new_data
            if {$new_data eq ""} {
                WarnFileNotFound $str $orig_new_gid $filename
            }
            set message "\"$filename\" @$old_gid with @$new_gid"
        }
        if {$old_data eq $new_data} {
            cli_misc::info "no differences $message"
            return
        }
        set old_data [split [encoding convertfrom utf-8 $old_data] "\n"]
        set new_data [split [encoding convertfrom utf-8 $new_data] "\n"]
        cli_misc::info "diff of $message"
        set delta [diff::diff $old_data $new_data]
        if {!$::VERBOSE} {
            set delta [diff::contextualize $delta]
        }
        set delta [diff::colorize $delta]
        puts [join $delta \n]
    } finally {
        $str destroy
    }
}

proc cli_actions::WarnFileNotFound {str gid filename} {
    set gids [$str gids_for_filename $filename]
    if {[llength $gids]} {
        set message "\"$filename\" @$gid not found in the store"
        cli_misc::warn "$message; try: [join $gids " "]"
    } else {
        cli_misc::warn "\"$filename\" is not in the store"
    }
}

proc cli_actions::filenames {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        foreach filename [$str filenames $gid] {
            set tracked [expr {[$str is_current $filename] \
                    ? "" : " ${::RED}(untracked)${::RESET}"}]
            cli_misc::info "$filename$tracked"
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::generations {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        if {$rest eq "-f" || $rest eq "--full"} {
            set prev_gid 0
            foreach {gid created message filename} [$str generations true] {
                if {$gid != $prev_gid} {
                    cli_misc::info "@$gid $created $message"
                    set prev_gid $gid
                }
                set tracked [expr {[$str is_current $filename] \
                        ? "" : " ${::RED}(untracked)${::RESET}"}]
                puts "  $filename$tracked"
            }
        } else {
            foreach {gid created message} [$str generations] {
                cli_misc::info "@$gid $created $message"
            }
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::history {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        set prev_name ""
        set prefix ""
        foreach {name gid} [$str history $rest] {
            if {$prev_name eq $name} {
                puts -nonewline " @$gid"
            } else {
                set prev_name $name
                set tracked [expr {[$str is_current $name] \
                    ? "" : " ${::RED}(untracked)${::RESET}"}]
                puts -nonewline "$prefix${::BLUE}$name${::RESET}$tracked\
                    @$gid"
                set prefix "\n"
            }
        }
        puts ""
    } finally {
        $str destroy
    }
}

proc cli_actions::ignore {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str patterns
    try {
        $str ignore {*}$patterns
    } finally {
        $str destroy
    }
}

proc cli_actions::ignores {reporter storefile} {
    lassign [GidStoreAndRest $reporter $storefile {}] gid str rest
    try {
        foreach pattern [$str ignores] {
            cli_misc::info $pattern
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::unignore {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str patterns
    try {
        $str unignore {*}$patterns
    } finally {
        $str destroy
    }
}

proc cli_actions::clean {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str clean
    } finally {
        $str destroy
    }
}

proc cli_actions::tag {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str tag $gid $rest
    } finally {
        $str destroy
    }
}

proc cli_actions::untag {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str untag $gid
    } finally {
        $str destroy
    }
}


proc cli_actions::untracked {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        foreach name [$str untracked] {
            cli_misc::info $name
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::restore {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] _ str rest
    try {
        $str restore {*}$rest
    } finally {
        $str destroy
    }
}

proc cli_actions::purge {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str filename
    try {
        if {[cli_misc::yes_no "permanently permanently purge \"$filename\"\
                          from the store" true]} {
            set n [$str purge $filename]
            lassign [misc::n_s $n] n s
            cli_misc::info "purged $n version$s"
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::GidStoreAndRest {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    lassign [GidAndRest $str $rest] gid rest
    list $gid $str $rest
}

proc cli_actions::GidAndRest {str rest} {
    set gid [$str current_generation]
    set first [lindex $rest 0]
    if {[string match {@[0-9]*} $first]} {
        set gid [string range $first 1 end]
        set rest [lrange $rest 1 end]
    }
    list $gid $rest
}
