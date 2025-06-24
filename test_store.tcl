#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

package require globals
package require misc
package require store

proc test1 {} {
    set procname [lindex [info level 0] 0]
    puts "##### $procname ##############################################"
    puts "Store verbose [Store verbose]"
    Store set_verbose true
    puts "Store verbose [Store verbose]"
    set filename /tmp/${procname}.db
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

proc test2 {} {
    set procname [lindex [info level 0] 0]
    puts "##### $procname ##############################################"
    Store set_verbose true
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    $str add sql/prepare.sql sql/create.sql app-1.tm store-1.tm
    $str add README.md
    $str update "should change nothing"
    # TODO add another generation but this means changing a file!
    $str destroy 
}

test1
test2
