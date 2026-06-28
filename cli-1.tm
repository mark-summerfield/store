# Copyright © 2025 Mark Summerfield. All rights reserved.

package require cli_actions
package require cli_globals
package require cli_misc
package require clop
package require lambda 1
package require store
package require textutil

namespace eval cli {}

proc cli::main {} {
    set storefile .[file tail [pwd]].str
    lassign [get_opts $storefile] subcommand opts
    dict set opts storefile $storefile
    dict set opts reporter [get_reporter $opts]
    switch $subcommand {
        add { cli_actions::add $opts }
        copy { cli_actions::copy $opts }
        clean { cli_actions::clean $opts }
        diff { cli_actions::diff $opts }
        extract { cli_actions::extract $opts }
        filenames { cli_actions::filenames $opts }
        generations { cli_actions::generations $opts }
        gui { package require gui ; gui::main }
        history { cli_actions::history $opts}
        ignore { cli_actions::ignore $opts }
        ignores { cli_actions::ignores $opts }
        print { cli_actions::print $opts }
        purge { cli_actions::purge $opts }
        optsore { cli_actions::optsore $opts }
        status { cli_actions::status $opts }
        tag { cli_actions::tag $opts }
        untracked { cli_actions::untracked $opts }
        unignore { cli_actions::unignore $opts }
        update { cli_actions::update $opts }
        untag { cli_actions::untag $opts }
    }
}

proc cli::get_reporter opts {
    set reporter filtered_reporter ;# ::VERBOSE is default of 1
    if {[dict getdef $opts quiet 0]} {
        set reporter ""
        set ::VERBOSE 0
    } elseif {[dict getdef $opts verbose 0]} {
        set reporter full_reporter
        set ::VERBOSE 2
    }
    return $reporter
}

proc cli::get_opts storefile {
    if {!$::argc} {
        if {[file exists $storefile]} {
            return [list status [dict create % {} verbose 0]]
        }
    }
    set parser [clop::Parser new str [cli::get_version $storefile] 255 \
        "Stores generational copies of specified files (excluding those
        explicitly ignored) in %y%I.dirname%!%y.str%!. (For a GUI run
        %B%bstore%!.)" \
        "%I%b@GID%! — @-prefixed generation number or tag name, (e.g.,\
        %y@28%!, %y@alpha1%!); if unspecified, the current generation is\
        assumed. %I%bGLOB%! — when using globs for ignore or unignore\
        use quotes to avoid shell expansion of glob characters (e.g.,\
        %y'*.o'%!). Subcommands that print output to %ystdour%! unless\
        redirected by the shell. For help on a specific subcommand follow\
        the subcommand with %g-h%! or %g--help%! or just use %gh%! or\
        %ghelp%! for full help."]

    $parser new_debug

    set status_parser [clop::subparser status $parser 0 \
        "Report the store’s status." \
        "Report any unstored unignored nonempty files and\
        whether updates or cleaning are needed. \[Default action for\
        %B%bstr%! with no arguments.\]"]
    $status_parser new_bool v verbose \
        "Print the name of every new/changed file \[default %mjust show\
        counts%!\]."
    $status_parser new_help h help "Show status help and quit."
    $parser new_subcommand s status $status_parser

    set update_parser [clop::subparser update $parser 0-1 \
        "Create a new generation with an optional tag." \
        "Updates all the files in the store by creating a new generation\
        and storing all those that have changed." \
        "For the %bTAG%! use quotes if multiple words."]
    $update_parser set_positional_names TAG
    $update_parser new_bool v verbose \
        "Show the name of every updated file \[default %mjust show\
        counts%!\]."
    $update_parser new_help h help "Show update help and quit."
    $parser new_subcommand u update $update_parser

    set add_parser [clop::subparser add $parser 0-255 \
        "Add the addable or the given files and folders." \
        "Add the given files and the files in the given folders to the\
        store. If none given then adds the files in the current folder and\
        its immediate subfolders, except for those ignored or empty,\
        creating the store if necessary." \
        "The given files and folders to add."]
    $add_parser new_bool v verbose \
        "Show the name of every added file \[default %mjust show\
        counts%!\]."
    $add_parser new_help h help "Show add help and quit."
    $parser new_subcommand a add $add_parser

    set extract_parser [clop::subparser extract $parser 1-255 \
        "Extract the specified files." \
        "Extract the given filenames at the generation, e.g.,\
        %yfilename.ext%! will be extracted as %yfilename@gid.ext%!, etc." \
        "%I%g@GID%! is the generation to extract \[default current\];\
        %bFILE1 … FILEn%! are the files to extract."]
    $extract_parser set_positional_line \
        "%I%g\[@GID\]%! %b<FILE1> … <FILEn>%!"
    $extract_parser new_bool v verbose \
        "Show the name of every extractd file \[default %mjust show\
        counts%!\]."
    $extract_parser new_help h help "Show extract help and quit."
    $parser new_subcommand e extract $extract_parser

    set print_parser [clop::subparser print $parser 1-2 \
        "Print the given file." \
        "Print the given file from the store at the given (or current
        if not specified) generation. (Should only be used for %Iplain
        text files%!!)." \
        "%I%g@GID%! is the generation to print from \[default current\];\
        %bFILE%! is the file to print."]
    $print_parser set_positional_line "%I%g\[@GID\]%! %b<FILE>%!"
    $print_parser new_help h help "Show print help and quit."
    $parser new_subcommand p print $print_parser

    set copy_parser [clop::subparser copy $parser 1-2 \
        "Copy a generation to the given folder." \
        "Copy all the files at the given or current generation into
        the given folder (which must not exist)." \
        "%I%g@GID%! is the generation to copy from \[default current\];\
        %bFOLDER%! is the folder to create and copy into."]
    $copy_parser set_positional_names @GID FOLDER
    $copy_parser set_positional_line "%g\[@GID\]%! %b<FOLDER>%!"
    $copy_parser new_bool v verbose "Show the name of every copied file."
    $copy_parser new_help h help "Show copy help and quit."
    $parser new_subcommand c copy $copy_parser

    set diff_parser [clop::subparser diff $parser 2-3 \
        "Diff the given file." \
        "Diff the filename at %b@GID1%! against the one in the current\
        folder, or against the one stored at %I%g@GID2%! if given; shows\
        the entire file, unless quiet is specified when only differences\
        and context lines are shown."\
        "%b@GID1%! is the first generation; %I%g@GID2%! is the second\
        generation \[default current\]; %bFILE%! is the file to diff at\
        these generations."]
    $diff_parser set_positional_names @GID FOLDER
    $diff_parser set_positional_line \
        "%b<@GID1>%! %I%g\[@GID2\]%! %b<FILE>%!"
    $diff_parser new_bool q quiet "Show the differences and some context\
        only \[default show the whole file\]."
    $diff_parser new_help h help "Show diff help and quit."
    $parser new_subcommand d diff $diff_parser

    set filenames_parser [clop::subparser filenames $parser 0-1 \
        "Print the list of tracked files." "" \
        "%I%g@GID%! is the generation to list \[default current\]."]
    $filenames_parser set_positional_names @GID
    $filenames_parser new_help h help "Show filenames help and quit."
    $parser new_subcommand f filenames $filenames_parser

    set generations_parser [clop::subparser generations $parser 0 \
        "Print the generations." \
        "Print the generations (and all their filenames if %I%g--full%!)."]
    $generations_parser new_bool f full "Show filenames."
    $generations_parser new_help h help "Show generations help and quit."
    $parser new_subcommand g generations $generations_parser

    set gui_parser [clop::subparser gui $parser 0 "Start the gui."]
    $gui_parser new_help h help "Show gui help and quit."
    $parser new_subcommand G gui $gui_parser

    set history_parser [clop::subparser history $parser 1-255 \
        "Print the given files’ list of generations." \
        "Print the given files’ list of generations back to when each was\
        first added." \
        "The files to print the history of."]
    $history_parser new_help h help "Show history help and quit."
    $parser new_subcommand H history $history_parser

    set ignore_parser [clop::subparser ignore $parser 1-255 \
        "Add the given files/folders/globs to the ignore list." \
        "Add the given filenames, folders, and globs to the list of files\
        to ignore." \
        "Each %bITEM%! is a file or a folder or a glob pattern."]
    $ignore_parser set_positional_names ITEM ITEM
    $ignore_parser new_help h help "Show ignore help and quit."
    $parser new_subcommand i ignore $ignore_parser

    set ignores_parser [clop::subparser ignores $parser 0 \
        "Print the list of files to ignore."]
    $ignores_parser new_help h help "Show ignores help and quit."
    $parser new_subcommand I ignores $ignores_parser

    set unignore_parser [clop::subparser unignore $parser 1-255 \
        "Remove the given files/folders/globs from the ignore list." \
        "Remove the given filenames, folders, and globs from the list of\
        files to ignore." \
        "Each %bITEM%! is a file or a folder or a glob pattern."]
    $unignore_parser set_positional_names ITEM ITEM
    $unignore_parser new_help h help "Show unignore help and quit."
    $parser new_subcommand U unignore $unignore_parser

    set tag_parser [clop::subparser tag $parser 1-2 \
        "Set or replace the tag for the current or given generation." \
        "Set or replace the tag for the current or given generation to\
        the given tag %I%moverwritting any existing tag%!." \
        "%I%g@GID%! is the generation to tag \[default current\]. For the\
        %bTAG%! use quotes if multiple words."]
    $tag_parser set_positional_line "%g<@GID>%! %b<TAG>%!"
    $tag_parser new_help h help "Show tag help and quit."
    $parser new_subcommand t tag $tag_parser

    set untag_parser [clop::subparser untag $parser 0-1 \
        "Untag the current or given generation." \
        "Untag, i.e., %I%mdelete%!, the current or given generation’s\
        tag." "%I%g@GID%! is the generation to untag \[default current\]."]
    $untag_parser set_positional_names GID
    $untag_parser new_help h help "Show untag help and quit."
    $parser new_subcommand "" untag $untag_parser

    set untracked_parser [clop::subparser untracked $parser 0 \
        "Print any untracked files."]
    $untracked_parser new_help h help "Show untracked help and quit."
    $parser new_subcommand T untracked $untracked_parser

    set restore_parser [clop::subparser restore $parser 1-255 \
        "Restore the specified files %I%moverwriting those on disk!%!" \
        "Restore the specified files by %I%moverwriting those on disk%!\
        with those from the store." "The files to restore."]
    $restore_parser new_help h help "Show restore help and quit."
    $parser new_subcommand "" restore $restore_parser

    set clean_parser [clop::subparser clean $parser 0 \
        "Clean the store by deleting empty generations." \
        "Clean the store by deleting empty generations, i.e., those\
        without any changes."]
    $clean_parser new_help h help "Show clean help and quit."
    $parser new_subcommand C clean $clean_parser

    set purge_parser [clop::subparser purge $parser 1 \
        "Purge the given file from the store." \
        "Purge the given file from the store by deleting every copy of\
        it at every generation." "The file to purge from the store."]
    $purge_parser new_help h help "Show purge help and quit."
    $parser new_subcommand "" purge $purge_parser

    set help_parser [clop::subparser add $parser 0 "Full help."]
    $parser new_help_subcommand h help $help_parser

    $parser new_version
    $parser new_help h help "Show this help and quit. Use %gh%! or\
        %ghelp%! for full help."
    set args [expr {$::argc ? $::argv : [list -h]}]
    set opts [$parser parse $args]
    list [dict get $opts *] $opts 
}

proc cli::get_version storefile {
    set version ?
    if {[file exists $storefile]} {
        set str [Store new $storefile]
        try {
            set version [$str version]
        } finally {
            $str destroy
        }
    }
    return $version
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
