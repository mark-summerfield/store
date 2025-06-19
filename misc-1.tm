# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

proc misc::read_file filename {
    set fh [open $filename]
    set data [read $fh]
    close $fh
    return $data
}

proc misc::sqlite_version {} {
    set db ::STORE#[clock micro]
    sqlite3 $db :memory:
    set version "SQLite [$db version]"
    $db close
    set db {}
    return $version
}
