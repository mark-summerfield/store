# Copyright © 2025 Mark Summerfield. All rights reserved.

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
                        if {![misc::ignore $subname $ignores]} {
                            lappend names $subname   
                        }
                    }
                } else {
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
        puts -nonewline [encoding convertfrom utf-8 $data]
    } finally {
        $str close
    }
}

proc actions::diff {reporter filename rest} {
    puts "TODO diff store=$filename rest=$rest" ;# TODO
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
    set gid [$str last_generation]
    set first [lindex $rest 0]
    if {[string match {@[0-9]} $first]} {
        set gid [string range $first 1 end]
        set rest [lrange $rest 1 end]
    }
    return [list $gid $str $rest]
}
