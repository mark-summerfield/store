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

Stores generational copies of specified files (excluding those explicitly
ignored) in .dirname.str. The user can view or diff or extract any previous
copy of any stored file.

For command line run `store help` for commands; for GUI run `store gui`.

## License

GPL-3

---
