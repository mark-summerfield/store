# Copyright © 2025 Mark Summerfield. All rights reserved.

package require diff
package require misc
package require store

namespace eval actions {}

# we deliberately only go at most one level deep for folders
proc actions::add {reporter filename rest} {
    set str [Store new $filename $reporter]
    try {
        set ignores [$str ignores]
        set names [list]
        foreach name $rest {
            if {![misc::ignore $name $ignores]} {
                if {[file isdirectory $name]} {
                    foreach subname [glob -directory $name -type f *] {
                        if {![misc::ignore $subname $ignores] &&
                                ![file attributes $subname -hidden]} {
                            lappend names $subname   
                        }
                    }
                } elseif {![file attributes $subname -hidden]} {
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

proc actions::update {reporter filename rest} {
    set message [join $rest " "]
    set str [Store new $filename $reporter]
    try {
        $str update $message
    } finally {
        $str close
    }
}

proc actions::extract {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        $str extract $gid {*}$rest
    } finally {
        $str close
    }
}

proc actions::copy {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        $str copy $gid $rest
    } finally {
        $str close
    }
}

proc actions::print {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        lassign [$str get $gid $rest] gid data
        if {$data ne ""} {
            puts -nonewline [encoding convertfrom utf-8 $data]
        } else {
            set gid [$str find_first_gid $rest]
            if {$gid} {
                puts "\"$rest\" was added to the store in generation @$gid"
            } else {
                puts "\"$rest\" is not in the store"
            }
        }
    } finally {
        $str close
    }
}

proc actions::diff {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid1 str rest
    try {
        lassign [GidAndRest $str $rest] gid2 rest
        if {$gid1 == $gid2} { ;# compare with file
            lassign [$str get $gid1 $rest] gid1 old_data
            if {$old_data eq ""} {
                warn "\"$rest\" @$gid1 not found in store"
            }
            set new_data [readFile $rest binary]
            set message "\"$rest\" @$gid1 with file on disk"
        } else { ;# compare in store
            if {$gid1 > $gid2} {
                lassign "$gid1 $gid2" gid2 gid1
            }
            lassign [$str get $gid1 $rest] gid1 old_data
            if {$old_data eq ""} {
                warn "\"$rest\" @$gid1 not found in store"
            }
            lassign [$str get $gid2 $rest] gid2 new_data
            if {$new_data eq ""} {
                warn "\"$rest\" @$gid2 not found in store"
            }
            set message "\"$rest\" @$gid1 with @$gid2"
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

proc actions::filenames {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        foreach filename [$str filenames $gid] {
            puts $filename
        }
    } finally {
        $str close
    }
}

proc actions::generations {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        foreach {gid created message} [$str generations] {
            puts "@$gid $created $message"
        }
    } finally {
        $str close
    }
}

proc actions::history {reporter filename rest} {
    set str [Store new $filename $reporter]
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

proc actions::ignore {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        $str ignore {*}$rest
    } finally {
        $str close
    }
}

proc actions::ignores {reporter filename} {
    lassign [GidStoreAndRest $reporter $filename {}] gid str rest
    try {
        foreach pattern [$str ignores] {
            puts $pattern
        }
    } finally {
        $str close
    }
}

proc actions::unignore {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        $str unignore {*}$rest
    } finally {
        $str close
    }
}

proc actions::purge {reporter filename rest} {
    lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
    try {
        puts -nonewline \
            "permanently purge \"$rest\" from the store \[yN]? "
        flush stdout
        set reply [read stdin 1]
        if {$reply eq "y"} {
            set n [$str purge $rest]
            lassign [misc::n_s $n] n s
            puts "purged $n version$s"
        }
    } finally {
        $str close
    }
}

proc actions::GidStoreAndRest {reporter filename rest} {
    set str [Store new $filename $reporter]
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
