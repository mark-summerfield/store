# Copyright © 2025 Mark Summerfield. All rights reserved.

# See: https://en.wikipedia.org/wiki/ANSI_escape_code
if {[dict exists [chan configure stdout] -mode]} { ;# tty
    set RESET "\033\[0m"
    set BOLD "\x1B\[1m"
    set ITALIC "\x1B\[3m"
    set RED "\x1B\[31m"
} else { ;# redirected
    set RESET ""
    set BOLD ""
    set ITALIC ""
    set RED ""
}
