#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

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
    try {
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
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test2 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok true
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    try {
        $str add sql/prepare.sql sql/create.sql app-1.tm store-1.tm
        $str add README.md
        $str update "should change nothing #1"
        $str update "should change nothing #2"
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test3 {expected reporter} {
    set ok true
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set filename /tmp/${procname}.db
    file delete $filename
    set ::messages [list]
    set str [Store new $filename $reporter]
    try {
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
            lappend ::messages "$procname: gid=$gid message=\"$message\"\n"
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
        $str copy 4 /tmp/$procname
        set create1 [readFile /tmp/$procname/sql/create.sql]
        set create2 [readFile sql/create.sql]
        if {$create1 ne $create2} {
            puts "FAIL: expected\n$create1\n--- got ---\n$create2"
            set ok false
        }
        file delete -force /tmp/$procname
    } finally {
        $str destroy 
    }
    set ::messages [string cat {*}$::messages]
    if {$::messages ne $expected} {
        puts "FAIL: expected\n$expected\n--- got ---\n$::messages"
        set ok false
    }
    if {$ok} { puts OK }
}

proc test4 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok true
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    try {
        catch { $str update "should cause error" } err_message
        if {$err_message ne "can only update an existing non-empty store"} {
            puts "FAIL: expected non-empty store error; got $err_message"
            set ok false
        }
        $str add README.md
        catch { $str update "should change nothing #1" } err_message
        if {$err_message ne "0" } {
            puts "FAIL: unexpected error; got $err_message"
            set ok false
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test5 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok true
    set filename /tmp/${procname}.db
    file delete $filename
    set expecteds {{*.a} {*.bak} {*.class} {*.dll} {*.exe} {*.jar} {*.ld} \
        {*.ldx} {*.li} {*.lix} {*.o} {*.obj} {*.py[co]} {*.rs.bk} \
        {*.so} {*.sw[nop]} {*.tmp} {*~} {[#]*#} {__pycache__} \
        {louti[0-9]*} {moc_*.cpp} {qrc_*.cpp} {test.*} {ui_*.h} {zOld}}
    set str [Store new $filename]
    try {
        set i 0
        foreach pattern [$str ignores] {
            set expected [lindex $expecteds $i]
            if {$pattern ne $expected} {
                puts "FAIL: expected \"$expected\"; got \"$pattern\""
                set ok false
            }
            incr i
        }
        set expecteds [linsert $expecteds 3 "*.com"]
        $str ignore "*.com"
        set i 0
        foreach pattern [$str ignores] {
            set expected [lindex $expecteds $i]
            if {$pattern ne $expected} {
                puts "FAIL: expected \"$expected\"; got \"$pattern\""
                set ok false
            }
            incr i
        }
        set expecteds [lremove $expecteds 3]
        $str unignore "*.com"
        set i 0
        foreach pattern [$str ignores] {
            set expected [lindex $expecteds $i]
            if {$pattern ne $expected} {
                puts "FAIL: expected \"$expected\"; got \"$pattern\""
                set ok false
            }
            incr i
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

const MESSAGES1 {created /tmp/test3.db
adding 4 new files
created generation #1
added "app-1.tm" (deflated)
added "sql/create.sql" (deflated)
added "sql/prepare.sql" (deflated)
added "store-1.tm" (deflated)
adding one new file
updating 4 files
created generation #2
same as generation #1 "app-1.tm"
added "README.md" (deflated)
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
updated "README.md" (deflated)
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
test3: gid=8 message="should change nothing #7"
test3: gid=7 message="should change nothing #6"
test3: gid=6 message="should restore old README.md #5"
test3: gid=5 message="should change to new README.md #4"
test3: gid=4 message="should change nothing #3"
test3: gid=3 message="should change nothing #2"
test3: gid=2 message="added one new file"
test3: gid=1 message="added 4 new files"
extracted "sql/prepare.sql" → "sql/prepare#1.sql"
extracted "README.md" → "README#5.md"
copied "README.md" → "/tmp/test3/README.md"
copied "sql/create.sql" → "/tmp/test3/sql/create.sql"
copied "sql/prepare.sql" → "/tmp/test3/sql/prepare.sql"
copied "store-1.tm" → "/tmp/test3/store-1.tm"
}

const MESSAGES2 {created /tmp/test3.db
adding 4 new files
created generation #1
adding one new file
updating 4 files
created generation #2
updating "should change nothing #2"
created generation #3
updating "should change nothing #3"
created generation #4
updating "should change to new README.md #4"
created generation #5
updated "README.md" (deflated)
updating "should restore old README.md #5"
created generation #6
updating "should change nothing #6"
created generation #7
updating "should change nothing #7"
created generation #8
test3: gid=8 message="should change nothing #7"
test3: gid=7 message="should change nothing #6"
test3: gid=6 message="should restore old README.md #5"
test3: gid=5 message="should change to new README.md #4"
test3: gid=4 message="should change nothing #3"
test3: gid=3 message="should change nothing #2"
test3: gid=2 message="added one new file"
test3: gid=1 message="added 4 new files"
extracted "sql/prepare.sql" → "sql/prepare#1.sql"
extracted "README.md" → "README#5.md"
copied "README.md" → "/tmp/test3/README.md"
copied "sql/create.sql" → "/tmp/test3/sql/create.sql"
copied "sql/prepare.sql" → "/tmp/test3/sql/prepare.sql"
copied "store-1.tm" → "/tmp/test3/store-1.tm"
}

proc full_reporter message { lappend ::messages "$message\n" }

cd $::APPPATH
test1
test2
puts "test3 with full reporter"
test3 $MESSAGES1 full_reporter
puts "test3 with filtered reporter"
test3 $MESSAGES2 [lambda {message} {
    if {[string match {test3*} $message] || \
            [string match {added*} $message] || \
            [string match {same as*} $message] } {
        return
    } else {
        lappend ::messages "$message\n"
    }
}]
test4
test5
