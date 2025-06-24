# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

proc misc::sqlite_version {} {
    set db ::STR#[string range [clock clicks] end-8 end]
    sqlite3 $db :memory:
    set version "SQLite [$db version]"
    $db close
    return $version
}

proc misc::n_s size {
    set n [expr {$size == 1 ? "one" : $size}]
    set s [expr {$size == 1 ? "" : "s"}]
    return [list $n $s]
}
