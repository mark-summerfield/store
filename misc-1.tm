# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

proc misc::ignore {filename ignores} {
    foreach pattern $ignores {
        if {[string match $pattern $filename]} { return true }
    }
    return false
}

proc misc::valid_file name {
    expr {![string match {.*} [file tail $name]] && [file size $name]}
}
