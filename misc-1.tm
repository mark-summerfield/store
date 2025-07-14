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

proc misc::valid_file name {
    expr {![string match {.*} [file tail $name]] && [file size $name]}
}

proc misc::human_size {value {suffix B} {dp 0}} {
    if {!$value} {
        return "$value $suffix"
    }
    set factor 1
    if {$value < 0} {
        set factor -1
        set value [expr {$value * $factor}]
    }

    set log_n [expr {int(log($value) / log(1024))}]
    set prefix [lindex [list "" "Ki" "Mi" "Gi" "Ti" "Pi" "Ei" "Zi" "Yi"] \
        $log_n]
    set value [expr {$value / (pow(1024, $log_n))}]
    set value [expr {$value * $factor}]
    return "[format %.${dp}f $value] ${prefix}${suffix}"
}
