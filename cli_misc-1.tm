# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_globals
package require term::receive

namespace eval cli_misc {}

# can't use cli_globals since they are for stdout and here we need stderr
proc cli_misc::warn message {
    if {[dict exists [chan configure stderr] -mode]} { ;# tty
        set reset "\033\[0m"
        set red "\x1B\[31m"
    } else { ;# redirected
        set reset ""
        set red ""
    }
    puts stderr "${red}$message${reset}"
    exit 1
}

proc cli_misc::info {message {need_action false}} {
    if {$need_action} {
        puts "${::MAGENTA}$message${::RESET}"
    } else {
        puts "${::BLUE}$message${::RESET}"
    }
}

proc cli_misc::yes_no {prompt {dangerous false}} {
    set color [expr {$dangerous ? $::RED : $::MAGENTA}]
    puts -nonewline "${color}$prompt \[yN]?${::RESET} "
    flush stdout
    expr {[string match -nocase y [term::receive::getch]]}
}

proc cli_misc::width {{defwidth 72}} {
    if {[dict exists [chan configure stdout] -mode]} { ;# tty
        return [lindex [chan configure stdout -winsize] 0]
    }
    return $defwidth
}
