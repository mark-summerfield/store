# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals
package require term::receive

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

proc misc::info {message {need_action false}} {
    if {$need_action} {
        puts "${::MAGENTA}$message${::RESET}"
    } else {
        puts "${::BLUE}$message${::RESET}"
    }
}

proc misc::yes_no {prompt {dangerous false}} {
    set color [expr {$dangerous ? $::RED : $::MAGENTA}]
    puts -nonewline "${color}$prompt \[yN]?${::RESET} "
    flush stdout
    expr {[string match -nocase y [term::receive::getch]]}
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
