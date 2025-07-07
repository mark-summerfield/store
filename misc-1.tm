# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

# inserts a string in case sensitive order into a list of strings if it
# is not already present
proc misc::insort {str_list s} {
    set pos [lsearch -bisect $str_list $s]
    if {$pos == -1 || [lindex $str_list $pos] ne $s} {
        return [linsert $str_list [incr pos] $s] ;# insert new unique string
    }
    return $str_list ;# ignore duplicate string
}

proc misc::n_s size {
    if {!$size} { return [list "no" "s"] }
    if {$size == 1} { return [list "one" ""] }
    list $size "s"
}

proc misc::sqlite_version {} {
    set db ::DB#[string range [clock clicks] end-8 end]
    sqlite3 $db :memory:
    try {
        return "SQLite [$db version]"
    } finally {
        $db close
    }
}

proc misc::ignore {filename ignores} {
    foreach pattern $ignores {
        if {[string match $pattern $filename]} { return true }
    }
    return false
}
