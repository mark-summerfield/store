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

proc misc::n_s size {
    if {$size == 1} { return [list "one" ""] }
    return [list $size "s"]
}
