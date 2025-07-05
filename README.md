# Store

An easy-to-use simple alternative to a version control system.

Add files to store:

    str l

or

    str list

This will glob the files in the current folder and its immediate subfolders
and filter out ignored and empty files to present a list of unstored files.
It will then prompt for whether to add the files to the store (creating the
store if necessary).

(Use `str list --no` in a shell script to provide a list of unstored
unignored nonempty files that are candidates to be added; the `--no`
prevents the interactive prompting to add.)

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

## License

GPL-3

---
