# Copyright © 2025 Mark Summerfield. All rights reserved.

package require actions
package require globals
package require gui

namespace eval app {}

proc app::main {} {
    if {!$::argc} usage
    set filename .[file tail [pwd]].str
    set command [lindex $::argv 0]
    lassign [get_reporter [lrange $::argv 1 end]] rest reporter
    switch $command {
        a - add { actions::add $reporter $filename $rest }
        c - copy { actions::copy $reporter $filename $rest }
        d - diff { actions::diff $reporter $filename $rest }
        e - extract { actions::extract $reporter $filename $rest }
        f - filenames { actions::filenames $reporter $filename $rest }
        g - generations { actions::generations $reporter $filename $rest }
        G - gui { gui::run $filename }
        h - help - -h - --help { usage } 
        i - ignore { actions::ignore $reporter $filename $rest }
        I - ignores { actions::ignores $reporter $filename }
        p - print { actions::print $reporter $filename $rest }
        purge { actions::purge $reporter $filename $rest }
        u - update { actions::update $reporter $filename $rest }
        U - unignore { actions::unignore $reporter $filename $rest }
        v - version - -v - --version { version }
        default { warn "unrecognized command: \"$command\"" }
    }
}

proc app::get_reporter rest {
    set reporter ""
    set first [lindex $rest 0]
    switch $first {
        -v - --verbose {
            set reporter filtered_reporter
            set rest [lrange $rest 1 end]
        }
        -V - --veryverbose {
            set reporter full_reporter
            set rest [lrange $rest 1 end]
        }
    }
    return [list $rest $reporter]
}

proc app::version {} {
    puts "store v$::VERSION"
    exit 2
}

proc app::usage {} {
    puts "${::ITALIC}usage: ${::RESET}${::BOLD}store${::RESET} <command> …

Stores generational copies of specified files (excluding those
explicitly ignored) in .${::ITALIC}dirname${::RESET}.str.

${::BOLD}a${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}add${::RESET}\
    \[verbose] <filename1|dirname1 \[… filenameN|dirnameN]>
  Adds the given files or the files in the given folders to the store,
  excluding any that are ignored, creating the store if necessary.
${::BOLD}u${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}update${::RESET}\
    \[verbose] \[optional message text]
  Updates all the files in the store by creating a new generation and
  storing all those that have changed.
${::BOLD}e${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}extract${::RESET}\
    \[verbose] \[@gid] <filename1 \[… filenameN]>
  Extracts the given filenames at the generation,
  e.g., filename.ext will be extracted as filename@gid.ext, etc.
${::BOLD}c${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}copy${::RESET}\
    \[verbose] \[@gid] <dirname>
  Copies all the files at the generation into the given dirname
  (which must not exist).
${::BOLD}p${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}print${::RESET}\
    \[@gid] <filename>
  Prints the given filename from the store at the generation,
  to stdout.
${::BOLD}d${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}diff${::RESET}\
    <@gid1> \[@gid2] <filename>
  Diffs the filename at @gid1 against the one in the current folder,
  or against the one stored at @gid2 if given.
${::BOLD}f${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}filenames${::RESET}\
    \[@gid]
  Prints the generation’s filenames to stdout.
${::BOLD}g${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}generations${::RESET}
  Prints the generation’s (number, created, message) to stdout.
${::BOLD}i${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}ignore${::RESET}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Adds the given filenames, folders, and globs to the ignore list.
${::BOLD}I${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}ignores${::RESET}
  Lists the filenames, folders, and globs in the ignore list.
${::BOLD}U${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}unignore${::RESET}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Unignores the given filenames, folders, and globs by removing them
  from the ignore list.
${::BOLD}purge${::RESET} <filename>
  Purges the given filename from the store by deleting every copy
  of it at every generation.
${::BOLD}G${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}gui${::RESET}
  Launch graphical user interface.
${::BOLD}h${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}help${::RESET}\
    ${::ITALIC}or${::RESET} ${::BOLD}-h${::RESET} ${::ITALIC}or${::RESET}\
    ${::BOLD}--help${::RESET}
  Show this usage message and exit.
${::BOLD}v${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}version${::RESET}\
    ${::ITALIC}or${::RESET} ${::BOLD}-v${::RESET} ${::ITALIC}or${::RESET}\
    ${::BOLD}--version${::RESET}
  Show store’s version and exit.

• @gid — @-prefixed generation number, e.g., @5;
  if unspecified, the last generation is assumed
• glob — when using globs for ignore or unignore use quotes
  to avoid shell expansion of glob characters (e.g., '*.o').
• verbose — specified as ${::BOLD}-v${::RESET} ${::ITALIC}or${::RESET}\
   ${::BOLD}--verbose${::RESET} ${::ITALIC}or${::RESET}\
   ${::BOLD}-V${::RESET} ${::ITALIC}or${::RESET}\
   ${::BOLD}-veryverbose${::RESET}"
    exit 2
}

proc filtered_reporter message {
    if {[string match {added*} $message] || \
            [string match {same as*} $message] } {
        return
    }
    puts $message
}

proc full_reporter message { puts $message }
