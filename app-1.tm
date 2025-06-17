# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals

namespace eval app {}

proc app::main {} {
    puts "store v$::VERSION"
}
