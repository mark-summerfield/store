# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_actions
package require cli_globals
package require cli_misc
package require lambda 1
package require store
package require textutil

namespace eval cli {}

proc cli::main {} {
    set storefile .[file tail [pwd]].str
    if {!$::argc} {
        if {[file exists $storefile]} {
            cli_actions::status "" $storefile {}
            exit
        } else {
            usage
        }
    }
    set command [lindex $::argv 0]
    lassign [get_reporter [lrange $::argv 1 end]] rest reporter
    switch $command {
        a - add { cli_actions::add $reporter $storefile $rest }
        c - copy { cli_actions::copy $reporter $storefile $rest }
        C - clean { cli_actions::clean $reporter $storefile $rest }
        d - diff { cli_actions::diff $reporter $storefile $rest }
        e - extract { cli_actions::extract $reporter $storefile $rest }
        f - filenames { cli_actions::filenames $reporter $storefile $rest }
        g - generations { cli_actions::generations $reporter $storefile \
                          $rest }
        G - gui { package require gui ; gui::main }
        h - help - -h - --help { usage } 
        help-full - --help-full - full-help - --full-help { usage_full }
        H - history { cli_actions::history $reporter $storefile $rest}
        i - ignore { cli_actions::ignore $reporter $storefile $rest }
        I - ignores { cli_actions::ignores $reporter $storefile }
        p - print { cli_actions::print $reporter $storefile $rest }
        purge { cli_actions::purge $reporter $storefile $rest }
        restore { cli_actions::restore $reporter $storefile $rest }
        s - status { cli_actions::status $reporter $storefile $rest }
        t - tag { cli_actions::tag $reporter $storefile $rest }
        T - untracked { cli_actions::untracked $reporter $storefile $rest }
        U - unignore { cli_actions::unignore $reporter $storefile $rest }
        u - update { cli_actions::update $reporter $storefile $rest }
        untag { cli_actions::untag $reporter $storefile $rest }
        v - version - -v - --version { cli_actions::version $reporter \
                                       $storefile $rest }
        default {
            if {$command ne ""} {
                cli_misc::warn "unrecognized command: \"$command\""
            }
        }
    }
}

proc cli::get_reporter rest {
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

proc cli::usage {} {
    set width [cli_misc::width]
    set width2 [expr {$width - 2}]
    puts [unmark "~usage: %^str% <command> …\n"]
    puts [unmark [textutil::adjust \
        "Stores generational copies of specified files (excluding those
        explicitly ignored) in .~dirname%.str.
        (For a GUI run ^store%.)" \
        -strictlength true -length $width]]
    puts ""
    say1 "^s% ~or% ^status% \[verbose\] — show store’s status"
    say1 "^u% ~or% ^update% \[verbose\] \[tag\] — creates a new generation"
    say1 "^a% ~or% ^add% \[verbose\] \[filename1|dirname1 …\
        filenameN|dirnameN\] — adds new files"
    say1 "^e% ~or% ^extract% \[verbose\] \[@gid\] <filename1\
        \[… filenameN\]> — extracts specified files"
    say1 "^p% ~or% ^print% \[@gid\] <filename> — prints file to stdout"
    say1 "^c% ~or% ^copy% \[verbose\] \[@gid\] <dirname> — copies\
        generation to a new folder"
    say1 "^d% ~or% ^diff% \[verbose] <@gid1> \[@gid2\] <filename> —\
        compares two generations of the file or the specified generation\
        with the file on disk"
    say1 "^f% ~or% ^filenames% \[@gid\] — prints the tracked files"
    say1 "^g% ~or% ^generations% \[^-f% ~or% ^--full%\] — prints the\
        generations"
    say1 "^G% ~or% ^gui% — starts the GUI"
    say1 "^H% ~or% ^history% \[filename\] — prints the file’s history"
    say1 "^i% ~or% ^ignore% <filename1|dirname1|glob1 \[…\
        filenameN|dirnameN|globN\]> — adds to the ignores"
    say1 "^I% ~or% ^ignores% — prints the ignores"
    say1 "^U% ~or% ^unignore% <filename1|dirname1|glob1 \[…\
        filenameN|dirnameN|globN\]> — removes from the ignores"
    say1 "^t% ~or% ^tag% \[@gid\] <tag> — tag the given or current\
        generation"
    say1 "^untag% \[@gid\] — untag the given or current generation"
    say1 "^T% ~or% ^untracked% — prints any untracked files"
    say1 "^restore% <filename1 \[… filenameN\]> — restores the specified\
        files overwriting those on disk"
    say1 "^C% ~or% ^clean% — deletes empty generations"
    say1 "^purge% <filename> — purges the file"
    say1 "^h% ~or% ^help% ~or% ^-h% ~or% ^--help% — shows this usage\
        message"
    say1 "^help-full% ~or% ^--help-full% ~or% ^full-help% ~or%\
        ^--full-help% — shows detailed usage"
    say1 "^v% ~or% ^version% ~or% ^-v% ~or% ^--version% — prints the\
        version"
    puts ""
    say1 "• @gid — @-prefixed generation number or tag name, (e.g., @28, \
        @alpha1), or current is assumed" $width2 "  "
    say1 "• glob — use quotes to avoid shell expansion (e.g., '*.o')." \
        $width2 "  "
    say1 "• verbose — ^-v% ~or% ^--verbose% full, ~or% ^-q% ~or%\
        ^--quiet% silent; default filtered." $width2 "  "
}

proc cli::usage_full {} {
    set width [cli_misc::width]
    set width2 [expr {$width - 2}]
    set indent "  "
    puts [unmark "~usage: %^str% <command> …\n"]
    puts [unmark [textutil::adjust \
        "Stores generational copies of specified files (excluding those
        explicitly ignored) in .~dirname%.str.
        (For a GUI run ^store%.)" \
        -strictlength true -length $width]]
    puts [unmark "\n^s% ~or% ^status% \[verbose\]"]
    say2 "Status reports any unstored unignored nonempty files and whether
        updates or cleaning are needed. (Default action for store.)"
    puts [unmark "^u% ~or% ^update% \[verbose\] \[tag\]"]
    say2 "Updates all the files in the store by creating a new generation
        and storing all those that have changed."
    puts [unmark "^a% ~or% ^add% \[verbose\] \[filename1|dirname1 …\
        filenameN|dirnameN\]"]
    say2 "Adds the given files or the files in the given folders to the
        store, or if none given then the files in the current folder and
        its immediate subfolders, except for those ignored or empty,
        creating the store if necessary." 
    puts [unmark "^e% ~or% ^extract% \[verbose\] \[@gid\] <filename1 \[…\
        filenameN\]>"]
    say2 "Extracts the given filenames at the generation, e.g.,
        filename.ext will be extracted as filename@gid.ext, etc."
    puts [unmark "^p% ~or% ^print% \[@gid\] <filename>"]
    say2 "Prints the given filename from the store at the generation,
        to stdout. (Should be used only for plain text files!)"
    puts [unmark "^c% ~or% ^copy% \[verbose\] \[@gid\] <dirname>"]
    say2 "Copies all the files at the generation into the given dirname
        (which must not exist)."
    puts [unmark "^d% ~or% ^diff% \[verbose] <@gid1> \[@gid2\] <filename>"]
    say2 "Diffs the filename at @gid1 against the one in the current folder,
        or against the one stored at @gid2 if given; shows the entire file,
        unless verbose is quiet when only differences and context lines are
        shown."
    puts [unmark "^f% ~or% ^filenames% \[@gid\]"]
    say2 "Prints the tracked files filenames to stdout."
    puts [unmark "^g% ~or% ^generations% \[full\]"]
    say2 "Prints all the generations (number, created, tag), and if
        \[full\] specified as ^-f% ^or% ^--full%, all their filenames, to
        stdout."
    puts [unmark "^G% ~or% ^gui%"]
    say2 "Starts the GUI."
    puts [unmark "^H% ~or% ^history% \[filename\]"]
    say2 "Prints the given file’s generations, or all the files’
        generations if no file specified, where a change has occurred,
        to stdout."
    puts [unmark "^i% ~or% ^ignore% <filename1|dirname1|glob1\
        \[… filenameN|dirnameN|globN\]>"]
    say2 "Adds the given filenames, folders, and globs to the ignore list."
    puts [unmark "^I% ~or% ^ignores%"]
    say2 "Lists the filenames, folders, and globs in the ignore list."
    puts [unmark "^U% ~or% ^unignore% <filename1|dirname1|glob1\
        \[… filenameN|dirnameN|globN\]>"]
    say2 "Unignores the given filenames, folders, and globs by removing them
        from the ignore list."
    puts [unmark "^t% ~or% ^tag% \[@gid\] <tag>"]
    say2 "Tag the given or current generation with the given tag."
    puts [unmark "^untag% \[@gid\]"]
    say2 "Untag the given or current generation."
    puts [unmark "^T% ~or% ^untracked%"]
    say2 "Lists any untracked files."
    puts [unmark "^restore% <filename1 \[… filenameN\]>"]
    say2 "Restores the specified files extracting them from the current
        generation and overwriting their namesakes on disk."
    puts [unmark "^C% ~or% ^clean%"]
    say2 "Cleans, i.e., deletes, every “empty” generation that has no
        changes."
    puts [unmark "^purge% <filename>"]
    say2 "Purges the given filename from the store by deleting every copy
        of it at every generation."
    puts [unmark "^h% ~or% ^help% ~or% ^-h% ~or% ^--help%"]
    say2 "Show short usage message and exit. (Default action if no store.)"
    puts [unmark "^help-full% ~or% ^--help-full% ~or% ^full-help% ~or%\
        ^--full-help%"]
    say2 "Show this usage message and exit."
    puts [unmark "^v% ~or% ^version% ~or% ^-v% ~or% ^--version%"]
    say2 "Show ^str%’s version and exit."
    puts ""
    say1 "• @gid — @-prefixed generation number or tag name, (e.g., @28,
        @alpha1); if unspecified, the current generation is assumed" 0 "  "
    say1 "• glob — when using globs for ignore or unignore use quotes
        to avoid shell expansion of glob characters (e.g., '*.o')." 0 "  "
    say1 "• verbose — default is filtered; otherwise specified as
        ^-v% ~or% ^--verbose% full, ~or% ^-q% ~or% ^--quiet% silent." 0 "  "
}

proc cli::unmark s {
    subst -nobackslashes -nocommands \
        [string map {"^" ${::BOLD} "~" ${::ITALIC} "%" ${::RESET}} $s]
}

proc cli::say1 {txt {width 0} {indent "     "}} {
    set width [expr {$width ? $width : [cli_misc::width]}]
    puts [unmark [textutil::indent [textutil::adjust $txt \
            -strictlength true -length $width] $indent 1]]
}

proc cli::say2 {txt {width 0} {indent "  "}} {
    set width [expr {$width ? $width : [cli_misc::width] - 2}]
    puts [unmark [textutil::indent [textutil::adjust $txt \
            -strictlength true -length $width] $indent]]
}

proc filtered_reporter message {
    if {[regexp {^(:?same as|skipped)} $message]} {
        return
    }
    cli_misc::info $message
}

proc full_reporter message { cli_misc::info $message }
