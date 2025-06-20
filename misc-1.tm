# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

proc misc::read_utf8 filename {
    set fh [open $filename]
    chan configure $fh -encoding utf-8
    set text [read $fh]
    close $fh
    return $text
}

proc misc::sqlite_version {} {
    set db ::STR#[string range [clock clicks] end-8 end]
    sqlite3 $db :memory:
    set version "SQLite [$db version]"
    $db close
    return $version
}
