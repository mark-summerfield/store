# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval db {}

proc db::sqlite_version {} {
    set db ::DB#[string range [clock clicks] end-8 end]
    sqlite3 $db :memory:
    try {
        return "SQLite [$db version]"
    } finally {
        $db close
    }
}

proc db::first {row {default {}}} {
    expr {[llength $row] ? [lindex $row 0] : $default}
}
