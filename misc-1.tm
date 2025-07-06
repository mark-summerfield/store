# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals

namespace eval misc {}

# inserts in case sensitive order into a list of strings
proc misc::insort {lst x} {
    set pos [lsearch -bisect $lst $x]
    if {$pos == -1 || [lindex $lst $pos] ne $x} {
        return [linsert $lst [incr pos] $x] ;# insert new unique element
    }
    return $lst ;# ignore duplicate element
}

# can't use globals since they are for stdout and here we need stderr
proc misc::warn message {
    if {[dict exists [chan configure stderr] -mode]} { ;# tty
        set reset "\033\[0m"
        set red "\x1B\[31m"
    } else { ;# redirected
        set reset ""
        set red ""
    }
    puts stderr "${red}$message${reset}"
    exit 1
}

proc misc::info message { puts "${::BLUE}$message${::RESET}" }

proc misc::sqlite_version {} {
    set db ::DB#[string range [clock clicks] end-8 end]
    sqlite3 $db :memory:
    try {
        return "SQLite [$db version]"
    } finally {
        $db close
    }
}

proc misc::n_s size {
    if {!$size} { return [list "no" "s"] }
    if {$size == 1} { return [list "one" ""] }
    return [list $size "s"]
}

proc misc::ignore {filename ignores} {
    foreach pattern $ignores {
        if {[string match $pattern $filename]} { return true }
    }
    return false
}

proc misc::yes_no {prompt {dangerous false}} {
    set color [expr {$dangerous ? $::RED : $::MAGENTA}]
    puts -nonewline "${color}$prompt \[yN]?${::RESET} "
    flush stdout
    set reply [read stdin 1]
    expr {$reply eq "y"}
}
