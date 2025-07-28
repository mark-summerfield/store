# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_actions
package require cli_globals
package require cli_misc
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
        help-full - --help-full { usage_full }
        H - history { cli_actions::history $reporter $storefile $rest}
        i - ignore { cli_actions::ignore $reporter $storefile $rest }
        I - ignores { cli_actions::ignores $reporter $storefile }
        p - print { cli_actions::print $reporter $storefile $rest }
        purge { cli_actions::purge $reporter $storefile $rest }
        s - status { cli_actions::status $reporter $storefile $rest }
        t - tag { cli_actions::tag $reporter $storefile $rest }
        T - untracked { cli_actions::untracked $reporter $storefile $rest }
        U - unignore { cli_actions::unignore $reporter $storefile $rest }
        u - update { cli_actions::update $reporter $storefile $rest }
        untag { cli_actions::untag $reporter $storefile $rest }
        v - version - -v - --version { version }
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

proc cli::version {} {
    cli_misc::info "str v$::VERSION"
    exit 2
}

proc cli::usage {} {
    set width [cli_misc::width]
    set width2 [expr {$width - 2}]
    set indent "     "
    puts [unmark "~usage: %^str% <command> …\n"]
    puts [unmark [textutil::adjust \
        "Stores generational copies of specified files (excluding those
        explicitly ignored) in .~dirname%.str.
        (For a GUI run ^store%.)" \
        -strictlength true -length $width]]
    puts ""
    puts [unmark [textutil::indent [textutil::adjust "^s% ~or% ^status%\
        \[verbose\] — show store’s status" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^u% ~or% ^update%\
        \[verbose\] \[tag\] — creates a new generation" \
        -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^a% ~or% ^add%\
        \[verbose\] \[filename1|dirname1 … filenameN|dirnameN\] — adds\
        new files" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^e% ~or% ^extract%\
        \[verbose\] \[@gid\] <filename1 \[… filenameN\]> — extracts\
        specified files" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^p% ~or% ^print%\
        \[@gid\] <filename> — prints file to stdout" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^c% ~or% ^copy%\
        \[verbose\] \[@gid\] <dirname> — copies generation to a new\
        folder" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^d% ~or% ^diff%\
        \[verbose] <@gid1> \[@gid2\] <filename> — compares twos\
        generations of the file" -strictlength true -length $width] \
        $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^f% ~or% ^filenames%\
        \[@gid\] — prints the tracked files" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^g% ~or%\
        ^generations% \[^-f% ~or% ^--full%\] — prints the generations" \
        -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^G% ~or% ^gui%\
        — starts the GUI" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^H% ~or% ^history%\
        \[filename\] — prints the file’s history" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^i% ~or% ^ignore%\
        <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN\]> — adds\
        to the ignores" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^I% ~or% ^ignores%\
        — prints theignores" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^U% ~or% ^unignore%\
        <filename1|dirname1|glob1 \[… filenameN|dirnameN|globN\]>\
        — removes from the ignores" -strictlength true -length $width] \
        $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^t% ~or% ^tag%\
        \[@gid\] <tag> — tag the given or current genration" \
        -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^untag%\
        \[@gid\] — untag the given or current genration" \
        -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^T% ~or%\
        ^untracked% — prints anyuntracked files" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^C% ~or% ^clean%\
        — deletes empty generations" -strictlength true -length $width] \
        $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^purge% <filename>\
        — purges the file" -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^h% ~or% ^help%\
        ~or% ^-h% ~or% ^--help% — shows this usage message" \
        -strictlength true -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^help-full% ~or%\
        ^--help-full% — shows detailed usage" -strictlength true \
        -length $width] $indent 1]]
    puts [unmark [textutil::indent [textutil::adjust "^v% ~or% ^version%\
        ~or% ^-v% ~or% ^--version% — prints the version" \
        -strictlength true -length $width] $indent 1]]
    puts ""
    puts [unmark [textutil::indent [textutil::adjust \
        "• @gid — @-prefixed generation number, (e.g., @28), or current is\
        assumed" -strictlength true -length $width2] "  " 1]]
    puts [unmark [textutil::indent [textutil::adjust \
        "• glob — use quotes to avoid shell expansion (e.g., '*.o')." \
        -strictlength true -length $width2] "  " 1]]
    puts [unmark [textutil::indent [textutil::adjust \
        "• verbose — ^-v% ~or% ^--verbose% full, ~or% ^-q% ~or%\
        ^--quiet% silent; default filtered." -strictlength true \
        -length $width2] "  " 1]]
}

proc cli::usage_full {} {
    set width [cli_misc::width]
    set width2 [expr {$width - 2}]
    puts [unmark "~usage: %^str% <command> …\n"]
    puts [unmark [textutil::adjust \
        "Stores generational copies of specified files (excluding those
        explicitly ignored) in .~dirname%.str.
        (For a GUI run ^store%.)" \
        -strictlength true -length $width]]
    puts [unmark "\n^s% ~or% ^status% \[verbose\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Status reports any unstored unignored nonempty files and whether
        updates or cleaning are needed. (Default action for store.)" \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^u% ~or% ^update% \[verbose\] \[tag\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Updates all the files in the store by creating a new generation
        and storing all those that have changed." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^a% ~or% ^add% \[verbose\] \[filename1|dirname1 …\
        filenameN|dirnameN\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Adds the given files or the files in the given folders to the
        store, or if none given then the files in the current folder and
        its immediate subfolders, except for those ignored or empty,
        creating the store if necessary." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^e% ~or% ^extract% \[verbose\] \[@gid\] <filename1 \[…\
        filenameN\]>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Extracts the given filenames at the generation, e.g.,
        filename.ext will be extracted as filename@gid.ext, etc." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^p% ~or% ^print% \[@gid\] <filename>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Prints the given filename from the store at the generation,
        to stdout. (Should be used only for plain text files!)" \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^c% ~or% ^copy% \[verbose\] \[@gid\] <dirname>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Copies all the files at the generation into the given dirname
        (which must not exist)." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^d% ~or% ^diff% \[verbose] <@gid1> \[@gid2\] <filename>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Diffs the filename at @gid1 against the one in the current folder,
        or against the one stored at @gid2 if given; shows the entire file,
        unless verbose is quiet when only differences and context lines are
        shown." \
            -strictlength true -length $width2] "  "]]
    puts [unmark "^f% ~or% ^filenames% \[@gid\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Prints the tracked files filenames to stdout." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^g% ~or% ^generations% \[full\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Prints all the generations (number, created, tag), and if
        \[full\] specified as ^-f% ^or% ^--full%, all their filenames, to
        stdout." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^G% ~or% ^gui%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Starts the GUI." -strictlength true -length $width2] "  "]]
    puts [unmark "^H% ~or% ^history% \[filename\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Prints the given file’s generations, or all the files’
        generations if no file specified, where a change has occurred,
        to stdout." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^i% ~or% ^ignore% <filename1|dirname1|glob1\
        \[… filenameN|dirnameN|globN\]>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Adds the given filenames, folders, and globs to the ignore list." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^I% ~or% ^ignores%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Lists the filenames, folders, and globs in the ignore list." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^U% ~or% ^unignore% <filename1|dirname1|glob1\
        \[… filenameN|dirnameN|globN\]>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Unignores the given filenames, folders, and globs by removing them
        from the ignore list." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^t% ~or% ^tag% \[@gid\] <tag>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Tag the given or current generation with the given tag." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^untag% \[@gid\]"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Untag the given or current generation." -strictlength true \
        -length $width2] "  "]]
    puts [unmark "^T% ~or% ^untracked%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Lists any untracked files." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^C% ~or% ^clean%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Cleans, i.e., deletes, every “empty” generation that has no
        changes." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^purge% <filename>"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Purges the given filename from the store by deleting every copy
        of it at every generation." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^h% ~or% ^help% ~or% ^-h% ~or% ^--help%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Show short usage message and exit. (Default action if no store.)" \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^help-full% ~or% ^--help-full%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Show this usage message and exit." \
        -strictlength true -length $width2] "  "]]
    puts [unmark "^v% ~or% ^version% ~or% ^-v% ~or% ^--version%"]
    puts [unmark [textutil::indent [textutil::adjust \
        "Show ^str%’s version and exit." \
        -strictlength true -length $width2] "  "]]
    puts ""
    puts [unmark [textutil::indent [textutil::adjust \
        "• @gid — @-prefixed generation number, e.g., @28;
        if unspecified, the current generation is assumed" \
        -strictlength true -length $width2] "  " 1]]
    puts [unmark [textutil::indent [textutil::adjust \
        "• glob — when using globs for ignore or unignore use quotes
        to avoid shell expansion of glob characters (e.g., '*.o')." \
        -strictlength true -length $width2] "  " 1]]
    puts [unmark [textutil::indent [textutil::adjust \
        "• verbose — default is filtered; otherwise specified as
        ^-v% ~or% ^--verbose% full, ~or% ^-q% ~or% ^--quiet% silent." \
        -strictlength true -length $width2] "  " 1]]
}

proc cli::unmark s {
    subst -nobackslashes -nocommands \
        [string map {"^" ${::BOLD} "~" ${::ITALIC} "%" ${::RESET}} $s]
}

proc filtered_reporter message {
    if {[regexp {^(:?same as|skipped)} $message]} {
        return
    }
    cli_misc::info $message
}

proc full_reporter message { cli_misc::info $message }
