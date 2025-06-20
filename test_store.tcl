#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

package require globals
package require misc
package require store

proc test1 {} {
    puts "Store feedback [Store feedback]"
    Store set_feedback $::FEEDBACK_FULL
    puts "Store feedback [Store feedback]"
    set basename [lindex [info level 0] 0]
    set filename /tmp/${basename}.db
    file delete $filename
    puts "using [misc::sqlite_version]"
    set str [Store new $filename]
    puts "store $str is [expr {[$str is_closed] ? "closed" : "open"}]"
    set gid [$str last_generation]
    puts "last_generation [expr {$gid == 0 ? "none" : $gid}]"
    if {[$str filename] ne $filename} {
        puts "expected '$filename'; got '[str filename]'"
    } else {
        puts "saved '[$str filename]'"
    }
    $str destroy 
}

test1
