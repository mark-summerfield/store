# Copyright © 2025 Mark Summerfield. All rights reserved.

package require misc
package require store

namespace eval actions {}

# we deliberately only go at most one level of depth for folders
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
        } else {
            warn "empty store created; no filenames to add"
        }
    } finally {
        $str close
    }
}

proc actions::update {reporter filename rest} {
    set message [join $rest " "]
    try {
        set str [Store new $filename $reporter]
        $str update $message
    } finally {
        $str close
    }
}

proc actions::extract {reporter filename rest} {
    try {
        lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
        $str extract $gid {*}$rest
    } finally {
        $str close
    }
}

proc actions::copy {reporter filename rest} {
    try {
        lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
        $str copy $gid $rest
    } finally {
        $str close
    }
}

proc actions::print {reporter filename rest} {
    try {
        lassign [GidStoreAndRest $reporter $filename $rest] gid str rest
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
    puts "TODO filenames store=$filename rest=$rest" ;# TODO
}

proc actions::generations {reporter filename rest} {
    puts "TODO generations store=$filename rest=$rest" ;# TODO
}

proc actions::ignore {reporter filename rest} {
    puts "TODO ignore store=$filename rest=$rest" ;# TODO
}

proc actions::ignores {reporter filename} {
    puts "TODO ignores store=$filename" ;# TODO
}

proc actions::unignore {reporter filename rest} {
    puts "TODO unignore store=$filename rest=$rest" ;# TODO
}

proc actions::purge {reporter filename rest} {
    puts "TODO purge store=$filename rest=$rest" ;# TODO
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
