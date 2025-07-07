# Copyright © 2025 Mark Summerfield. All rights reserved.

const VERSION 0.6.0

set VERBOSE 1 ;# 0 → quiet; 1 → filtered; 2 → full

# See: https://en.wikipedia.org/wiki/ANSI_escape_code
if {[dict exists [chan configure stdout] -mode]} { ;# tty
    set RESET "\033\[0m"
    set BOLD "\x1B\[1m"
    set ITALIC "\x1B\[3m"
    set RED "\x1B\[31m"
    set GREEN "\x1B\[32m"
    set BLUE "\x1B\[34m"
    set MAGENTA "\x1B\[35m"
} else { ;# redirected
    set RESET ""
    set BOLD ""
    set ITALIC ""
    set RED ""
    set GREEN ""
    set BLUE ""
    set MAGENTA ""
}
