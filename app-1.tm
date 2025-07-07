# Copyright © 2025 Mark Summerfield. All rights reserved.

package require actions
package require globals

namespace eval app {}

proc app::main {} {
    set storefile .[file tail [pwd]].str
    if {!$::argc} {
        if {[file exists $storefile]} {
            actions::status "" $storefile {}
            exit 0
        } else {
            usage
        }
    }
    set command [lindex $::argv 0]
    lassign [get_reporter [lrange $::argv 1 end]] rest reporter
    switch $command {
        a - add { actions::add $reporter $storefile $rest }
        c - copy { actions::copy $reporter $storefile $rest }
        C - clean { actions::clean $reporter $storefile $rest }
        d - diff { actions::diff $reporter $storefile $rest }
        e - extract { actions::extract $reporter $storefile $rest }
        f - filenames { actions::filenames $reporter $storefile $rest }
        g - generations { actions::generations $reporter $storefile $rest }
        h - help - -h - --help { usage } 
        H - history { actions::history $reporter $storefile $rest}
        i - ignore { actions::ignore $reporter $storefile $rest }
        I - ignores { actions::ignores $reporter $storefile }
        p - print { actions::print $reporter $storefile $rest }
        purge { actions::purge $reporter $storefile $rest }
        s - status { actions::status $reporter $storefile $rest }
        u - update { actions::update $reporter $storefile $rest }
        U - unignore { actions::unignore $reporter $storefile $rest }
        v - version - -v - --version { version }
        default { misc::warn "unrecognized command: \"$command\"" }
    }
}

proc app::get_reporter rest {
    set reporter filtered_reporter ;# ::VERBOSE is default of 1
    set first [lindex $rest 0]
    switch $first {
        -v - --verbose {
            set reporter full_reporter
            set rest [lrange $rest 1 end]
            set ::VERBOSE 2
        }
        -q - --quiet {
            set reporter ""
            set rest [lrange $rest 1 end]
            set ::VERBOSE 0
        }
    }
    list $rest $reporter
}

proc app::version {} {
    misc::info "str v$::VERSION"
    exit 2
}

proc app::usage {} {
    puts "${::ITALIC}usage: ${::RESET}${::BOLD}str${::RESET} <command> …

Stores generational copies of specified files (excluding those
explicitly ignored) in .${::ITALIC}dirname${::RESET}.str.\
(For a GUI run ${::BOLD}store${::RESET}.)

${::BOLD}s${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}status${::RESET}\
    \[verbose]
  Status reports any unstored unignored nonempty files and whether
  updates or cleaning are needed. (Default action for store.)
${::BOLD}u${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}update${::RESET}\
    \[verbose] \[optional message text]
  Updates all the files in the store by creating a new generation and
  storing all those that have changed.
${::BOLD}a${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}add${::RESET}\
    \[verbose] \[filename1|dirname1 … filenameN|dirnameN]
  Adds the given files or the files in the given folders to the store,
  or if none given then the files in the current folder and its
  immediate subfolders, except for those ignored or empty,
  creating the store if necessary.
${::BOLD}e${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}extract${::RESET}\
    \[verbose] \[@gid] <filename1 \[… filenameN]>
  Extracts the given filenames at the generation,
  e.g., filename.ext will be extracted as filename@gid.ext, etc.
${::BOLD}p${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}print${::RESET}\
    \[@gid] <filename>
  Prints the given filename from the store at the generation,
  to stdout. (Should be used only for plain text files!)
${::BOLD}c${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}copy${::RESET}\
    \[verbose] \[@gid] <dirname>
  Copies all the files at the generation into the given dirname
  (which must not exist).
${::BOLD}d${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}diff${::RESET}\
    <@gid1> \[@gid2] <filename>
  Diffs the filename at @gid1 against the one in the current folder,
  or against the one stored at @gid2 if given.
${::BOLD}f${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}filenames${::RESET}\
    \[@gid]
  Prints the generation’s filenames to stdout.
${::BOLD}H${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}history${::RESET}\
    \[filename]
  Prints the given file’s generations, or all the files’ generations
  if no file specified, where a change has occurred, to stdout.
${::BOLD}g${::RESET} ${::ITALIC}or${::RESET}\
  ${::BOLD}generations${::RESET} \[full]
  Prints all the generations (number, created, message), and if
  \[full] specified as ${::BOLD}-f${::RESET} ${::ITALIC}or${::RESET}\
  ${::BOLD}--full${::RESET}, all their filenames, to stdout.
${::BOLD}i${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}ignore${::RESET}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Adds the given filenames, folders, and globs to the ignore list.
${::BOLD}I${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}ignores${::RESET}
  Lists the filenames, folders, and globs in the ignore list.
${::BOLD}U${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}unignore${::RESET}\
    <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN]>
  Unignores the given filenames, folders, and globs by removing them
  from the ignore list.
${::BOLD}C${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}clean${::RESET}
  Cleans, i.e., deletes, every “empty” generation that has no changes.
${::BOLD}purge${::RESET} <filename>
  Purges the given filename from the store by deleting every copy
  of it at every generation.
${::BOLD}h${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}help${::RESET}\
    ${::ITALIC}or${::RESET} ${::BOLD}-h${::RESET} ${::ITALIC}or${::RESET}\
    ${::BOLD}--help${::RESET}
  Show this usage message and exit. (Default action if no store.)
${::BOLD}v${::RESET} ${::ITALIC}or${::RESET} ${::BOLD}version${::RESET}\
    ${::ITALIC}or${::RESET} ${::BOLD}-v${::RESET} ${::ITALIC}or${::RESET}\
    ${::BOLD}--version${::RESET}
  Show store’s version and exit.

• @gid — @-prefixed generation number, e.g., @28;
  if unspecified, the last generation is assumed
• glob — when using globs for ignore or unignore use quotes
  to avoid shell expansion of glob characters (e.g., '*.o').
• verbose — default is filtered; otherwise specified as
  ${::BOLD}-v${::RESET} ${::ITALIC}or${::RESET}\
  ${::BOLD}--verbose${::RESET} full, ${::ITALIC}or${::RESET}\
  ${::BOLD}-q${::RESET} ${::ITALIC}or${::RESET}\
  ${::BOLD}--quiet${::RESET} silent."
    exit 2
}

proc filtered_reporter message {
    if {[regexp {^(:?added|same as)} $message]} {
        return
    }
    misc::info $message
}

proc full_reporter message { misc::info $message }
