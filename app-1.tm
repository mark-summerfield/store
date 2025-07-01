# Copyright © 2025 Mark Summerfield. All rights reserved.

package require actions
package require gui

namespace eval app {}

proc app::main {} {
    if {$::argc == 0 || [lsearch -exact $::argv -h] >= 0 || \
                        [lsearch -exact $::argv help] >= 0 || \
                        [lsearch -exact $::argv --help] >= 0} usage
    set reporter ""
    set filename .[file tail [pwd]].str
    set command [lindex $::argv 0]
    set argv [lrange $::argv 1 end]
    set first [lindex $argv 0]
    switch $first {
        -v -
        --verbose {
            set reporter filtered_reporter
            set argv [lrange $argv 1 end]
        }
        -V -
        --veryverbose {
            set reporter full_reporter
            set argv [lrange $argv 1 end]
        }
    }
    switch $command {
        a -
        add { actions::add $reporter $filename $argv }
        c -
        copy { actions::copy $reporter $filename $argv }
        d -
        diff { actions::diff $filename $argv }
        e -
        extract { actions::extract $reporter $filename $argv }
        f -
        filenames { actions::filenames $filename $argv }
        g -
        generations { actions::generations $filename $argv }
        G -
        gui { gui::run $filename }
        i -
        ignore { actions::ignore $filename $argv }
        I -
        ignores { actions::ignores $filename }
        p -
        print { actions::print $filename $argv }
        P -
        purge { actions::purge $filename $argv }
        u -
        update { actions::update $reporter $filename $argv }
        U -
        unignore { actions::unignore $filename $argv }
        -v -
        --version -
        v -
        version { version }
        default { warn "unrecognized command: \"$command\"" }
    }
}

proc app::verbose argv {
    upvar $argv argv
    set first [lindex $argv 0]
    switch $first {
        -v -
        --verbose {
            set reporter filtered_reporter
            set argv [lrange $argv 1 end]
        }
        -V -
        --veryverbose {
            set reporter full_reporter
            set argv [lrange $argv 1 end]
        }
    }
}

proc app::version {} {
    puts "store v$::VERSION"
    exit 2
}

proc app::warn message {
    if {[dict exists [chan configure stderr] -mode]} { ;# tty
        set reset "\033\[0m"
        set red "\x1B\[31m"
    } else { ;# redirected
        set reset ""
        set red ""
    }
    puts stderr "${red}$message${reset}"
}

proc app::usage {} {
    lassign [esc_codes] reset bold italic
    puts "${italic}usage: ${reset}${bold}store${reset} <command> …

Stores generational copies of specified files (excluding those
explicitly ignored) in .${italic}dirname${reset}.str.

${bold}a${reset} ${italic}or${reset} ${bold}add${reset} \[verbose]\
    <filename1|dirname1 \[… filenameN|dirnameN]>
  Adds the given files or the files in the given folders to the store,
  excluding any that are ignored, creating the store if necessary.
${bold}u${reset} ${italic}or${reset} ${bold}update${reset} \[verbose]\
\[optional message text]
  Updates all the files in the store by creating a new generation and
  storing all those that have changed.
${bold}e${reset} ${italic}or${reset} ${bold}extract${reset} \[verbose]\
    \[#gid] <filename1 \[… filenameN]>
  Extracts the given filenames at the generation,
  e.g., filename.ext will be extracted as filename#gid.ext, etc.
${bold}c${reset} ${italic}or${reset} ${bold}copy${reset} \[verbose]\
\[#gid] <dirname>
  Copies all the files at the generation into the given dirname
  (which must not exist).
${bold}p${reset} ${italic}or${reset} ${bold}print${reset} \[#gid]\
    <filename>
  Prints the given filename from the store at the generation,
  to stdout.
${bold}d${reset} ${italic}or${reset} ${bold}diff${reset}\
    <#gid1> \[#gid2] <filename>
  Diffs the filename at #gid1 against the one in the current folder,
  or against the one stored at #gid2 if given.
${bold}f${reset} ${italic}or${reset} ${bold}filenames${reset} \[#gid]
  Prints the generation’s filenames to stdout.
${bold}g${reset} ${italic}or${reset} ${bold}generations${reset}
  Prints the generation’s (number, created, message) to stdout.
${bold}i${reset} ${italic}or${reset} ${bold}ignore${reset}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Adds the given filenames, folders, and globs to the ignore list.
${bold}I${reset} ${italic}or${reset} ${bold}ignores${reset}
  Lists the filenames, folders, and globs in the ignore list.
${bold}U${reset} ${italic}or${reset} ${bold}unignore${reset}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Unignores the given filenames, folders, and globs by removing them
  from the ignore list.
${bold}P${reset} ${italic}or${reset} ${bold}purge${reset} <filename>
  Purges the given filename from the store by deleting every copy
  of it at every generation.
${bold}G${reset} ${italic}or${reset} ${bold}gui${reset}
  Launch graphical user interface.
${bold}h${reset} ${italic}or${reset} ${bold}help${reset}\
    ${italic}or${reset} ${bold}-h${reset} ${italic}or${reset}\
    ${bold}--help${reset}
  Show this usage message and exit.
${bold}v${reset} ${italic}or${reset} ${bold}version${reset}\
    ${italic}or${reset} ${bold}-v${reset} ${italic}or${reset}\
    ${bold}--version${reset}
  Show store’s version and exit.

• #gid — #-prefixed generation number, e.g., #5;
  if unspecified, the last generation is assumed
• glob — when using globs for ignore or unignore use quotes
  to avoid shell expansion of glob characters (e.g., '*.o').
• verbose — specified as ${bold}-v${reset} ${italic}or${reset}\
   ${bold}--verbose${reset} ${italic}or${reset} ${bold}-V${reset} ${italic}or${reset} ${bold}-veryverbose${reset}"
    exit 2
}

# See: https://en.wikipedia.org/wiki/ANSI_escape_code
proc esc_codes {} {
    if {[dict exists [chan configure stdout] -mode]} { ;# tty
        set reset "\033\[0m"
        set bold "\x1B\[1m"
        set italic "\x1B\[3m"
    } else { ;# redirected
        set reset ""
        set bold ""
        set italic ""
    }
    return [list $reset $bold $italic]
}

proc filtered_reporter message {
    if {[string match {added*} $message] || \
            [string match {same as*} $message] } {
        return
    }
    puts $message
}

proc full_reporter message { puts $message }
