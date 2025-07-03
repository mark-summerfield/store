# Copyright © 2025 Mark Summerfield. All rights reserved.

package require diff
package require misc
package require store

namespace eval actions {}

# we deliberately only go at most one level deep for folders
proc actions::add {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    try {
        set ignores [$str ignores]
        set names [list]
        foreach name $rest {
            if {![misc::ignore $name $ignores]} {
                if {[file isdirectory $name]} {
                    foreach subname [glob -directory $name -types f *] {
                        if {![misc::ignore $subname $ignores] &&
                                ![string match {.*} [file tail $name]]} {
                            lappend names $subname   
                        }
                    }
                } elseif {![string match {.*} [file tail $name]]} {
                    lappend names $name
                }
            }
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
        $str update $message
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

proc actions::copy {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str dirname
    try {
        $str copy $gid $dirname
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
                puts "\"$filename\" was added to the store in @$gid"
            } else {
                puts "\"$filename\" is not in the store"
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
            puts "no differences $message"
            return
        }
        set old_data [split [encoding convertfrom utf-8 $old_data] "\n"]
        set new_data [split [encoding convertfrom utf-8 $new_data] "\n"]
        puts "diff of $message"
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
            puts $filename
        }
    } finally {
        $str close
    }
}

proc actions::generations {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str rest
    try {
        foreach {gid created message} [$str generations] {
            puts "@$gid $created $message"
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
                puts -nonewline "$prefix$name @$gid"
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
            puts $pattern
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

proc actions::purge {reporter storefile rest} {
    lassign [GidStoreAndRest $reporter $storefile $rest] gid str filename
    try {
        puts -nonewline \
            "permanently purge \"$filename\" from the store \[yN]? "
        flush stdout
        set reply [read stdin 1]
        if {$reply eq "y"} {
            set n [$str purge $filename]
            lassign [misc::n_s $n] n s
            puts "purged $n version$s"
        }
    } finally {
        $str close
    }
}

proc actions::GidStoreAndRest {reporter storefile rest} {
    set str [Store new $storefile $reporter]
    lassign [GidAndRest $str $rest] gid rest
    return [list $gid $str $rest]
}

proc actions::GidAndRest {str rest} {
    set gid [$str last_generation]
    set first [lindex $rest 0]
    if {[string match {@[0-9]*} $first]} {
        set gid [string range $first 1 end]
        set rest [lrange $rest 1 end]
    }
    return [list $gid $rest]
}
