# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals
package require store

namespace eval app {}

proc app::main {} {
    puts "store v$::VERSION"
}
