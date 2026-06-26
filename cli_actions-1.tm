# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_misc
package require diff
package require store
package require util

namespace eval cli_actions {}

proc cli_actions::add opts {
    set files [dict get $opts %]
    set str [GetStore $opts]
    try {
        if {$files eq ""} {
            set names [$str addable]
        } else {
            set names [$str candidates_from_given $files]
        }
        if {[llength $names]} { $str add {*}$names }
    } finally {
        $str destroy
    }
}

proc cli_actions::update opts {
    set message [join [dict getdef $opts % " "]]
    set str [GetStore $opts]
    try {
        if {[$str have_updates]} {
            $str update $message
        } elseif {$::VERBOSE > 1} {
            cli_misc::info "no updates needed"
        }
        set names [$str addable]
        if {$::VERBOSE && [llength $names]} {
            lassign [util::n_s [llength $names]] n s
            cli_misc::info "$n unstored unignored nonempty file$s present" \
                true
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::extract opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid  rest
        $str extract $gid {*}$rest
    } finally {
        $str destroy
    }
}

proc cli_actions::status opts {
    set yes_messages [list]
    set no_messages [list]
    set str [GetStore $opts]
    try {
        set names [$str addable]
        if {[llength $names]} {
            lassign [util::n_s [llength $names]] n s
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
            lassign [util::n_s [llength $names]] n s
            lappend yes_messages "$n file$s to update"
            if {$::VERBOSE > 1} {
                lappend yes_messages \
                    {*}[lmap name $names {expr {"  $name"}}]
            }
        } elseif {$::VERBOSE} {
            lappend no_messages "up to date"
        }
        if {$::VERBOSE && [$str needs_clean]} {
            lappend yes_messages "clean needed"
        } elseif {$::VERBOSE} {
            lappend no_messages "clean"
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

proc cli_actions::copy opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid dirname
        $str copy $gid $dirname
    } on error err {
        cli_misc::warn $err
    } finally {
        $str destroy
    }
}

proc cli_actions::print opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid filename
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

proc cli_actions::diff opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] old_gid rest
        lassign [GetGidAndRest $str $rest] new_gid filename
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
        set old_data [split [encoding convertfrom utf-8 $old_data] \n]
        set new_data [split [encoding convertfrom utf-8 $new_data] \n]
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

proc cli_actions::filenames opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid rest
        foreach filename [$str filenames $gid] {
            set tracked [expr {[$str is_current $filename] \
                    ? "" : " ${::RED}(untracked)${::RESET}"}]
            cli_misc::info "$filename$tracked"
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::generations opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid rest
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

proc cli_actions::history opts {
    set str [GetStore $opts]
    try {
        set prev_name ""
        set prefix ""
        foreach {name gid} [$str history [dict get $opts %]] {
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

proc cli_actions::ignore opts {
    set str [GetStore $opts]
    try {
        $str ignore {*}[dict get $opts %]
    } finally {
        $str destroy
    }
}

proc cli_actions::ignores opts {
    set str [GetStore $opts]
    try {
        foreach pattern [$str ignores] { cli_misc::info $pattern }
    } finally {
        $str destroy
    }
}

proc cli_actions::unignore opts {
    set str [GetStore $opts]
    try {
        $str unignore {*}[dict get $opts %]
    } finally {
        $str destroy
    }
}

proc cli_actions::clean opts {
    set str [GetStore $opts]
    try {
        $str clean
    } finally {
        $str destroy
    }
}

proc cli_actions::tag opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid rest
        $str tag $gid $rest
    } on error err {
        cli_misc::warn "failed to add tag '$rest': $err"
    } finally {
        $str destroy
    }
}

proc cli_actions::untag opts {
    set str [GetStore $opts]
    try {
        lassign [GetGidAndRest $str [dict get $opts %]] gid _
        $str untag $gid
    } finally {
        $str destroy
    }
}


proc cli_actions::untracked opts {
    set str [GetStore $opts]
    try {
        foreach name [$str untracked] { cli_misc::info $name }
    } finally {
        $str destroy
    }
}

proc cli_actions::restore opts {
    set str [GetStore $opts]
    try {
        $str restore {*}[dict get $opts %]
    } finally {
        $str destroy
    }
}

proc cli_actions::purge opts {
    set str [GetStore $opts]
    try {
        set filename [dict get $opts %]
        if {[cli_misc::yes_no "permanently permanently purge \"$filename\"\
                          from the store" true]} {
            set n [$str purge $filename]
            lassign [util::n_s $n] n s
            cli_misc::info "purged $n version$s"
        }
    } finally {
        $str destroy
    }
}

proc cli_actions::GetStore opts {
    Store new [dict get $opts storefile] [dict get $opts reporter]
}

proc cli_actions::GetGidAndRest {str rest} {
    set gid [$str current_generation]
    set first [lindex $rest 0]
    if {[string match {@[0-9]*} $first]} {
        set gid [string range $first 1 end]
        set rest [lrange $rest 1 end]
    } elseif {[string match {@?*} $first]} {
        set tag [string range $first 1 end]
        set gid [$str gid_for_tag $tag]
        if {!$gid} { cli_misc::warn "tag \"$tag\" not found" }
        set rest [lrange $rest 1 end]
    }
    list $gid $rest
}
