#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

package require globals
package require lambda 1
package require misc
package require store

proc test1 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok true
    set filename /tmp/${procname}.db
    file delete $filename
    set sqlite_version [misc::sqlite_version]
    if {![string match {SQLite 3.*} $sqlite_version]} {
        puts "FAIL: expected SQLite 3.x.y; got $sqlite_version"
        set ok false
    }
    set str [Store new $filename]
    if {[$str is_closed]} {
        puts "FAIL: expected store to be open"
        set ok false
    }
    set gid [$str last_generation]
    if {$gid != 0} {
        puts "FAIL: expected no last generation; got $gid"
        set ok false
    }
    if {[$str filename] ne $filename} {
        puts "FAIL: expected '$filename'; got '[str filename]'"
        set ok false
    }
    $str destroy 
    if {$ok} { puts OK }
}

proc test2 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok true
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    $str add sql/prepare.sql sql/create.sql app-1.tm store-1.tm
    $str add README.md
    $str update "should change nothing #1"
    $str update "should change nothing #2"
    $str destroy 
    if {$ok} { puts OK }
}

proc test3 {} {
    set ok true
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set filename /tmp/${procname}.db
    file delete $filename
    set ::messages [list]
    set str [Store new $filename [lambda {message} {
        lappend ::messages "$message\n"
        #puts $message
    }]]
    $str add sql/prepare.sql sql/create.sql app-1.tm store-1.tm
    $str add README.md
    $str update "should change nothing #[$str last_generation]"
    $str update "should change nothing #[$str last_generation]"
    # change README.md
    set readme [readFile README.md]
    set readmex "$readme\nanother line\nand more!\n"
    writeFile README.md $readmex
    $str update "should change to new README.md #[$str last_generation]"
    # restore original README.md
    writeFile README.md $readme
    $str update "should restore old README.md #[$str last_generation]"
    $str update "should change nothing #[$str last_generation]"
    $str update "should change nothing #[$str last_generation]"
    foreach {gid created message} [$str generations] {
        lappend ::messages "gid=$gid message=\"$message\"\n"
    }
    set n [$str purge app-1.tm]
    if {$n != 8} {
        puts "FAIL: expected 8 deletions of app-1.tm; got $n"
        set ok false
    }
    $str extract 5 sql/prepare.sql README.md
    set readmex2 [readFile README#5.md]
    if {$readmex2 ne $readmex} {
        puts "FAIL: expected\n$readmex\n--- got ---\n$readmex"
        set ok false
    }
    file delete README#5.md
    set prep1 [readFile sql/prepare.sql]
    set prep2 [readFile sql/prepare#1.sql]
    if {$prep1 ne $prep2} {
        puts "FAIL: expected\n$prep1\n--- got ---\n$prep1"
        set ok false
    }
    file delete sql/prepare#1.sql
    $str destroy 
    set ::messages [string cat {*}$::messages]
    if {$::messages ne $::MESSAGES} {
        puts "FAIL: expected\n$::MESSAGES\n--- got ---\n$::messages"
        set ok false
    }
    if {$ok} { puts OK }
}

const MESSAGES {adding 4 new files
created generation #1
added "app-1.tm" (compressed)
added "sql/create.sql" (compressed)
added "sql/prepare.sql" (compressed)
added "store-1.tm" (compressed)
adding one new file
updating 4 files
created generation #2
same as generation #1 "app-1.tm"
added "README.md" (compressed)
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should change nothing #2"
created generation #3
same as generation #1 "app-1.tm"
same as generation #2 "README.md"
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should change nothing #3"
created generation #4
same as generation #1 "app-1.tm"
same as generation #2 "README.md"
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should change to new README.md #4"
created generation #5
same as generation #1 "app-1.tm"
updated "README.md" (compressed)
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should restore old README.md #5"
created generation #6
same as generation #1 "app-1.tm"
same as generation #2 "README.md"
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should change nothing #6"
created generation #7
same as generation #1 "app-1.tm"
same as generation #2 "README.md"
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
updating "should change nothing #7"
created generation #8
same as generation #1 "app-1.tm"
same as generation #2 "README.md"
same as generation #1 "sql/create.sql"
same as generation #1 "sql/prepare.sql"
same as generation #1 "store-1.tm"
gid=8 message="should change nothing #7"
gid=7 message="should change nothing #6"
gid=6 message="should restore old README.md #5"
gid=5 message="should change to new README.md #4"
gid=4 message="should change nothing #3"
gid=3 message="should change nothing #2"
gid=2 message="added one new file"
gid=1 message="added 4 new files"
extracted "sql/prepare.sql" → "sql/prepare#1.sql"
extracted "README.md" → "./README#5.md"
}

test1
test2
test3
