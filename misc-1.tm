# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

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
