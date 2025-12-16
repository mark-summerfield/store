#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

const APPPATH [file normalize [file dirname [info script]]]
tcl::tm::path add $APPPATH

package require db
package require lambda 1
package require misc
package require store

proc test1 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok 1
    set filename /tmp/${procname}.db
    file delete $filename
    set sqlite_version [db::sqlite_version]
    if {![string match {SQLite 3.*} $sqlite_version]} {
        puts "FAIL: expected SQLite 3.x.y; got $sqlite_version"
        set ok 0
    }
    set str [Store new $filename]
    try {
        set gid [$str current_generation]
        if {$gid != 0} {
            puts "FAIL: expected no current generation; got $gid"
            set ok 0
        }
        if {[$str filename] ne $filename} {
            puts "FAIL: expected \"$filename\"; got \"[$str filename]\""
            set ok 0
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test2 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok 1
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    try {
        $str add sql/prepare.sql sql/create.sql cli-1.tm store-1.tm
        $str add README.md
        $str update "should change nothing @1"
        $str update "should change nothing @2"
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test3 {expected reporter} {
    set ok 1
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set filename /tmp/${procname}.db
    file delete $filename
    set ::messages [list]
    set str [Store new $filename $reporter]
    try {
        $str add sql/prepare.sql sql/create.sql cli-1.tm store-1.tm
        $str add README.md
        $str update "should change nothing @[$str current_generation]"
        $str update "should change nothing @[$str current_generation]"
        if {![$str is_current README.md]} {
            puts "FAIL: expected README.md to be current"
            set ok 0
        }
        # change README.md
        set readme [readFile README.md]
        set readmex "$readme\nanother line\nand more!\n"
        writeFile README.md $readmex
        $str update "should change to new README.md\
            @[$str current_generation]"
        # restore original README.md
        writeFile README.md $readme
        $str update "should restore old README.md\
            @[$str current_generation]"
        $str update "should change nothing @[$str current_generation]"
        $str update "should change nothing @[$str current_generation]"
        foreach {gid created tag} [$str generations] {
            lappend ::messages "$procname: gid=$gid tag=\"$tag\"\n"
        }
        set n [$str purge cli-1.tm]
        if {$n != 8} {
            puts "FAIL: expected 8 deletions of cli-1.tm; got $n"
            set ok 0
        }
        if {[$str is_current cli-1.tm]} {
            puts "FAIL: expected cli-1.tm to not be current"
            set ok 0
        }
        $str extract 5 sql/prepare.sql README.md
        set readmex2 [readFile README@5.md]
        if {$readmex2 ne $readmex} {
            puts "FAIL: expected\n$readmex\n--- got ---\n$readmex"
            set ok 0
        }
        file delete README@5.md
        set prep1 [readFile sql/prepare.sql]
        set prep2 [readFile sql/prepare@1.sql]
        if {$prep1 ne $prep2} {
            puts "FAIL: expected\n$prep1\n--- got ---\n$prep1"
            set ok 0
        }
        file delete sql/prepare@1.sql
        $str copy 4 /tmp/$procname
        set create1 [readFile /tmp/$procname/sql/create.sql]
        set create2 [readFile sql/create.sql]
        if {$create1 ne $create2} {
            puts "FAIL: expected\n$create1\n--- got ---\n$create2"
            set ok 0
        }
        file delete -force /tmp/$procname
    } finally {
        $str destroy 
    }
    set ::messages [string cat {*}$::messages]
    if {$::messages ne $expected} {
        puts "FAIL: expected\n$expected\n--- got ---\n$::messages"
        set ok 0
    }
    if {$ok} { puts OK }
}

proc test4 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok 1
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    try {
        if {[$str to_string] ne "Store \"/tmp/$procname.db\""} {
            puts "FAIL: expected 'Store \"/tmp/$procname.db\"'; got\
                \"[$str to_string]\""
            set ok 0
        }
        catch { $str update "should cause error" } err_message
        if {$err_message ne "can only update an existing nonempty store"} {
            puts "FAIL: expected nonempty store error; got $err_message"
            set ok 0
        }
        $str add README.md
        catch { $str update "should change nothing @1" } err_message
        if {$err_message ne "0" } {
            puts "FAIL: unexpected error; got $err_message"
            set ok 0
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test5 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok 1
    set filename /tmp/${procname}.db
    file delete $filename
    set expecteds {{*.a} {*.bak} {*.class} {*.dll} {*.exe} {*.jar} \
        {*.jpeg} {*.jpg} {*.ld} {*.ldx} {*.li} {*.lix} {*.o} {*.obj} \
        {*.png} {*.py[co]} {*.rs.bk} {*.so} {*.svg} {*.sw[nop]} {*.tmp} \
        {*~} {[#]*#} {__pycache__} {louti[0-9]*} {moc_*.cpp} {qrc_*.cpp} \
        {test*} {tmp/*} {ui_*.h} {zOld/*}}
    set str [Store new $filename]
    try {
        set i 0
        foreach pattern [$str ignores] {
            set expected [lindex $expecteds $i]
            if {$pattern ne $expected} {
                puts "FAIL: expected \"$expected\"; got \"$pattern\""
                set ok 0
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
                set ok 0
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
                set ok 0
            }
            incr i
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

proc test6 {} {
    set procname [lindex [info level 0] 0]
    puts -nonewline "$procname "
    set ok 1
    set filename /tmp/${procname}.db
    file delete $filename
    set str [Store new $filename]
    try {
        if {[$str to_string] ne "Store \"/tmp/$procname.db\""} {
            puts "FAIL: expected 'Store \"/tmp/$procname.db\"'; got\
                \"[$str to_string]\""
            set ok 0
        }
        $str add sql/prepare.sql sql/create.sql cli-1.tm
        $str tag 0 first
        $str add README.md store-1.tm
        $str tag 0 second
        set tag [$str tag 1]
        if {$tag ne "first"} {
            puts "FAIL: expected tag \"first\"'; got \"$tag\""
            set ok 0
        }
        set gid [$str gid_for_tag first]
        if {$gid != 1} {
            puts "FAIL: expected gid 1; got $gid"
            set ok 0
        }
        set tag [$str tag 2]
        if {$tag ne "second"} {
            puts "FAIL: expected tag \"second\"'; got \"$tag\""
            set ok 0
        }
        set gid [$str gid_for_tag second]
        if {$gid != 2} {
            puts "FAIL: expected gid 2; got $gid"
            set ok 0
        }
        set tag [$str tag 3]
        if {$tag ne ""} {
            puts "FAIL: expected tag \"\"'; got \"$tag\""
            set ok 0
        }
        set gid [$str gid_for_tag none-such]
        if {$gid != 0} {
            puts "FAIL: expected gid 0; got $gid"
            set ok 0
        }
    } finally {
        $str destroy 
    }
    if {$ok} { puts OK }
}

const MESSAGES1 {adding/updating
created @1
added   "cli-1.tm"
added   "sql/create.sql"
added   "sql/prepare.sql"
added   "store-1.tm"
adding/updating
created @2
same as @1 "cli-1.tm"
added   "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should change nothing @2"
created @3
same as @1 "cli-1.tm"
same as @2 "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should change nothing @3"
created @4
same as @1 "cli-1.tm"
same as @2 "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should change to new README.md @4"
created @5
same as @1 "cli-1.tm"
updated "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should restore old README.md @5"
created @6
same as @1 "cli-1.tm"
same as @2 "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should change nothing @6"
created @7
same as @1 "cli-1.tm"
same as @2 "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
updating with tag "should change nothing @7"
created @8
same as @1 "cli-1.tm"
same as @2 "README.md"
same as @1 "sql/create.sql"
same as @1 "sql/prepare.sql"
same as @1 "store-1.tm"
test3: gid=8 tag="should change nothing @7"
test3: gid=7 tag="should change nothing @6"
test3: gid=6 tag="should restore old README.md @5"
test3: gid=5 tag="should change to new README.md @4"
test3: gid=4 tag="should change nothing @3"
test3: gid=3 tag="should change nothing @2"
test3: gid=2 tag=""
test3: gid=1 tag=""
extracted "sql/prepare.sql" → "sql/prepare@1.sql"
extracted "README.md" → "README@5.md"
copied "README.md" → "/tmp/test3/README.md"
copied "sql/create.sql" → "/tmp/test3/sql/create.sql"
copied "sql/prepare.sql" → "/tmp/test3/sql/prepare.sql"
copied "store-1.tm" → "/tmp/test3/store-1.tm"
}

const MESSAGES2 {adding/updating
created @1
adding/updating
created @2
updating with tag "should change nothing @2"
created @3
updating with tag "should change nothing @3"
created @4
updating with tag "should change to new README.md @4"
created @5
updating with tag "should restore old README.md @5"
created @6
updating with tag "should change nothing @6"
created @7
updating with tag "should change nothing @7"
created @8
test3: gid=8 tag="should change nothing @7"
test3: gid=7 tag="should change nothing @6"
test3: gid=6 tag="should restore old README.md @5"
test3: gid=5 tag="should change to new README.md @4"
test3: gid=4 tag="should change nothing @3"
test3: gid=3 tag="should change nothing @2"
test3: gid=2 tag=""
test3: gid=1 tag=""
extracted "sql/prepare.sql" → "sql/prepare@1.sql"
extracted "README.md" → "README@5.md"
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
            [string match {updated*} $message] || \
            [string match {same as*} $message] } {
        return
    }
    lappend ::messages "$message\n"
}]
test4
test5
test6
