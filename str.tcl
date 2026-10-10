#!/usr/bin/env tclsh9
# Copyright © 2025-26 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

const VERSION 1.8.1

package require cli
package require cli_globals

proc error args {
    puts "${::RED}error: [join $args]$::RESET"
    exit 1
}

cli::main
