# Copyright © 2025 Mark Summerfield. All rights reserved.

set VERBOSE 1 ;# 0 → quiet; 1 → filtered; 2 → full

# See: https://en.wikipedia.org/wiki/ANSI_escape_code
if {[dict exists [chan configure stdout] -mode]} { ;# tty
    const RESET "\033\[0m"
    const BOLD "\x1B\[1m"
    const ITALIC "\x1B\[3m"
    const RED "\x1B\[31m"
    const GREEN "\x1B\[32m"
    const BLUE "\x1B\[34m"
    const MAGENTA "\x1B\[35m"
} else { ;# redirected
    const RESET ""
    const BOLD ""
    const ITALIC ""
    const RED ""
    const GREEN ""
    const BLUE ""
    const MAGENTA ""
}
