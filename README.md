# Store

An easy-to-use simple alternative to a version control system.

Add files to store:

    store a *

or

    store add *

This will add all the globbed files apart from those that match the default
ignore globs (e.g., `*.bak`, `*.o`, `*.obj`, etc.). You can add, remove, or
list the ignores (filenames, folder names, or globs).

The most common operation is to update the store after changes:

    store u

or

    store update

or, say,

    store u This is an optional comment.

You can print or extract any previous version of any stored file.
You can diff a previous version against the version on disk or against a
different previous version.

You can also extract all the files in a previous “generation” into a new
folder (using the `copy` command).

For command line run `store help` for commands; for GUI run `store gui`.

The generational copies of the added files are stored in _.dirname_.str.

Store does not support branching, staging, or anything else that’s
complicated, making it ideal for small personal projects where you just want
to save regular “checkpoints” of your changes and be able to look back in
time.

## License

GPL-3

---
