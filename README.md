# Store

An easy-to-use and simple alternative to a version control system.

There is a GUI application, `store.tk`, often soft-linked simply as `store`,
and a command line tool, `str.tcl`, often soft-linked as `str`.

## GUI — store.tk

![Screenshot](images/screenshot.png)

This provides the same facilities as the command line but can be much more
convenient for viewing and diffing previous generations of files.

Run the GUI using:

    store.tk

or

    store

where `store` is a soft link to `store.tk`.

## Command Line — str.tcl

Here it is assumed that `str` is a soft-link to `str.tcl`.

Add files:

    str a

or

    str add

This will glob the files in the current folder and its immediate subfolders
and filter out ignored and empty files to present a list of unstored files.
It will then prompt for whether to add the files to the store (creating the
store if necessary). It will also prompt for updates.

(Use `str s -q` or `str status --quiet` in a shell script to provide a list
of unstored unignored nonempty files that are candidates to be added; the
`-q` or `--quiet` prevents the interactive prompting to add or update.)

Alternatively, add specified or globbed files like this:

    str a *

or

    str add *

This will add all the specified files apart from those that match the
default ignore globs (e.g., `*.bak`, `*.o`, `*.obj`, etc.).

You can also add, remove, or list the ignores (filenames, folder names, or
globs).

The most common operation is to update the store after changes:

    str u

or

    str update

or, say,

    str u This is an optional comment.

Use

    str s

or `str status` to see if any files need adding or updating.

You can print or extract any previous version of any stored file.
You can diff a previous version against the version on disk or against a
different previous version.

To see if there are any files not in the store that are not ignored (e.g.,
new candidates for adding), run `str s` or `str status`.

You can also extract all the files in a previous “generation” into a new
folder (using the `copy` command).

The command line application is `str`; run `str help` for commands.
The GUI app is `store`.

The generational copies of the added files are stored in _.dirname_.str.

Store does not support branching, staging, or anything else that’s
complicated, making it ideal for small personal projects where you just want
to save regular “generations” of your changes and be able to look back in
time.


## Installation

Unpack anywhere convenient and either put the folder in your `PATH` or add
soft links to `str.tcl` as `str` and to `store.tk` as `store`.

Dependencies: Tcl/Tk >= 9.0.2; Tcllib >= 2.0; Tklib >= 0.9.

## License

GPL-3

---
