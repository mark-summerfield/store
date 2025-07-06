# Copyright © 2025 Mark Summerfield. All rights reserved.

package require diff
package require misc
package require store

namespace eval actions {}

proc actions::add {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        if {$rest eq ""} {
            set names [CandidatesForAdd $str]
        } else {
            set names [CandidatesFromGiven $str $rest]
        }
        if {[llength $names]} {
            $str add {*}$names
        }
    } finally {
        $str close
    }
}

proc actions::update {reporter storefile rest} {
    set message [join $rest " "]
    set str [Store new $storefile $reporter]
    try {
        if {[HaveUpdates $str]} {
            $str update $message
        } elseif {$::VERBOSE > 1} {
            misc::info "no updates needed"
        }
        if {$::VERBOSE && [llength [CandidatesForAdd $str]]} {
            misc::info "unstored unignored nonempty files present"
        }
    } finally {
        $str close
    }
}

proc actions::extract {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str extract $gid {*}$rest
    } finally {
        $str close
    }
}

proc actions::status {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        if {[llength [CandidatesForAdd $str]]} {
            misc::info "unstored unignored nonempty files present"
        } elseif {$::VERBOSE > 1} {
            misc::info "no files need adding"
        }
        if {[HaveUpdates $str]} {
            misc::info "updates needed"
        } elseif {$::VERBOSE > 1} {
            misc::info "no updates needed"
        }
        if {$::VERBOSE && [$str needs_clean]} {
            misc::info "clean needed"
        } elseif {$::VERBOSE > 1} {
            misc::info "no clean needed"
        }
    } finally {
        $str close
    }
}

proc actions::copy {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str dirname
    try {
        $str copy $gid $dirname
    } trap {} {message} {
        $str close
        misc::warn $message
    } finally {
        $str close
    }
}

proc actions::print {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str filename
    try {
        lassign [$str get $gid $filename] gid data
        if {$data ne ""} {
            puts -nonewline [encoding convertfrom utf-8 $data]
        } else {
            set gid [$str find_first_gid $filename]
            if {$gid} {
                misc::info "\"$filename\" was added to the store in @$gid"
            } else {
                misc::info "\"$filename\" is not in the store"
            }
        }
    } finally {
        $str close
    }
}

proc actions::diff {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid1 str rest
    try {
        lassign [GidAndRest $str $rest] gid2 filename
        if {$gid1 == $gid2} { ;# compare with file
            lassign [$str get $gid1 $filename] gid1 old_data
            if {$old_data eq ""} {
                misc::warn "\"$filename\" @$gid1 not found in store"
            }
            set new_data [readFile $filename binary]
            set message "\"$filename\" @$gid1 with file on disk"
        } else { ;# compare in store
            if {$gid1 > $gid2} {
                lassign "$gid1 $gid2" gid2 gid1
            }
            lassign [$str get $gid1 $filename] gid1 old_data
            if {$old_data eq ""} {
                misc::warn "\"$filename\" @$gid1 not found in store"
            }
            lassign [$str get $gid2 $filename] gid2 new_data
            if {$new_data eq ""} {
                misc::warn "\"$filename\" @$gid2 not found in store"
            }
            set message "\"$filename\" @$gid1 with @$gid2"
        }
        if {$old_data eq $new_data} {
            misc::info "no differences $message"
            return
        }
        set old_data [split [encoding convertfrom utf-8 $old_data] "\n"]
        set new_data [split [encoding convertfrom utf-8 $new_data] "\n"]
        misc::info "diff of $message"
        set delta [diff::diff $old_data $new_data]
        puts -nonewline $delta
    } finally {
        $str close
    }
}

proc actions::filenames {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        foreach filename [$str filenames $gid] {
            misc::info $filename
        }
    } finally {
        $str close
    }
}

proc actions::generations {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        if {$rest eq "-f" || $rest eq "--full"} {
            set prev_gid 0
            foreach {gid created message filename} [$str generations true] {
                if {$gid != $prev_gid} {
                    misc::info "@$gid $created $message"
                    set prev_gid $gid
                }
                puts "  $filename"
            }
        } else {
            foreach {gid created message} [$str generations] {
                misc::info "@$gid $created $message"
            }
        }
    } finally {
        $str close
    }
}

proc actions::history {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        set prev_name ""
        set prefix ""
        foreach {name gid} [$str history $rest] {
            if {$prev_name eq $name} {
                puts -nonewline " @$gid"
            } else {
                set prev_name $name
                puts -nonewline "$prefix${::BLUE}$name${::RESET} @$gid"
                set prefix "\n"
            }
        }
        puts ""
    } finally {
        $str close
    }
}

proc actions::ignore {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str patterns
    try {
        $str ignore {*}$patterns
    } finally {
        $str close
    }
}

proc actions::ignores {reporter storefile} {
    lassign [GidStoreAndRest $reporter $storefile {}] gid str rest
    try {
        foreach pattern [$str ignores] {
            misc::info $pattern
        }
    } finally {
        $str close
    }
}

proc actions::unignore {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str patterns
    try {
        $str unignore {*}$patterns
    } finally {
        $str close
    }
}

proc actions::clean {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        $str clean
    } finally {
        $str close
    }
}

proc actions::purge {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str filename
    try {
        if {[misc::yes_no "permanently permanently purge \"$filename\"\
                          from the store" true]} {
            set n [$str purge $filename]
            lassign [misc::n_s $n] n s
            misc::info "purged $n version$s"
        }
    } finally {
        $str close
    }
}

# For speed this only compares file sizes so will miss the hopefully rare
# cases when a file has been changed but is exactly the same size.
proc actions::HaveUpdates str {
    foreach file_size [$str file_sizes] {
        if {[file size [$file_size filename]] != [$file_size size]} {
            return true
        }
    }
    return false
}

proc actions::CandidatesForAdd str {
    set candidates [CandidatesFromGiven $str [glob * */*]]
    lmap name $candidates { ;# drop already stored files
        expr {[$str find_first_gid $name] ? [continue] : $name}
    }
}

# we deliberately only go at most one level deep for folders
proc actions::CandidatesFromGiven {str candidates} {
    set ignores [$str ignores]
    set names [list]
    foreach name $candidates {
        if {![misc::ignore $name $ignores]} {
            if {[file isdirectory $name]} {
                foreach subname [glob -directory $name -types f *] {
                    if {![misc::ignore $subname $ignores] &&
                            [ValidFile $subname]} {
                        lappend names $subname   
                    }
                }
            } elseif {[ValidFile $name]} {
                lappend names $name
            }
        }
    }
    return $names
}

proc actions::ValidFile name {
    expr {![string match {.*} [file tail $name]] && [file size $name]}
}

proc actions::GidStoreAndRest {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    lassign [GidAndRest $str $rest] gid rest
    list $gid $str $rest
}

proc actions::GidAndRest {str rest} {
    set gid [$str last_generation]
    set first [lindex $rest 0]
    if {[string match {@[0-9]*} $first]} {
        set gid [string range $first 1 end]
        set rest [lrange $rest 1 end]
    }
    list $gid $rest
}
