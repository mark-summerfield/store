#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

package require misc
package require store

proc test1 {} {
    puts [misc::sqlite_version]
    set st [Store new /tmp/test1.db]
    puts "store=$st is_closed=[$st is_closed]"
    $st destroy 
}

test1
