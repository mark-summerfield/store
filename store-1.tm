# Copyright © 2025 Mark Summerfield. All rights reserved.

package require filedata
package require globals
package require lambda 1
package require misc
package require sqlite3 3

oo::class create Store {
    variable Filename
    variable Db
    variable Reporter
}

# creates database if it doesn't exist
oo::define Store constructor {filename {reporter ""}} {
    set Filename $filename
    if {$reporter eq ""} {
        set Reporter [lambda {message} {}]
    } else {
        set Reporter $reporter
    }
    set Db ::STR#[string range [clock clicks] end-8 end]
    set exists [file isfile $Filename]
    sqlite3 $Db $Filename
    $Db eval [readFile $::APPPATH/sql/prepare.sql] 
    if {!$exists} {
        $Db eval [readFile $::APPPATH/sql/create.sql] 
    }
}

oo::define Store destructor { my close }

oo::define Store method close {} {
    if {![my is_closed]} {
        $Db close
        set Db {}
    }
}

oo::define Store method is_closed {} { catch {$Db version} }

oo::define Store method filename {} { return $Filename }

oo::define Store method last_generation {} {
    set gid [$Db eval {SELECT * FROM LastGeneration}]
    expr {$gid == "{}" ? 0 : int($gid)}
}

# Creates new generation with 'U' or 'Z' or 'S' for every given file
# returns the number of files added. (Excludes should be handled by the
# application itself.)
oo::define Store method add {args} {
    set size [llength $args]
    lassign [misc::n_s $size] n s
    set filenames [my filenames]
    {*}$Reporter "adding $n new file$s"
    set size2 [llength $filenames]
    if {$size2 > 0 } {
        lassign [misc::n_s $size2] n2 s2
        {*}$Reporter "updating $n2 file$s2"
    }
    set filenames [lsort -nocase [list {*}$filenames {*}$args]]
    return [my Update "added $n new file$s" true {*}$filenames]
}

# if at least one prev generation exists, creates new generation with
# 'U' or 'Z' or 'S' for every file present in the _last_ generation that
# hasn't been deleted and returns the number updated; otherwise does
# nothing and returns 0
oo::define Store method update {message} {
    set gid [my last_generation]
    if {$gid == 0} { return 0 }
    {*}$Reporter "updating \"$message\""
    return [my Update $message false {*}[my filenames $gid]]
}

# creates new generation with 'U' or 'Z' or 'S' for every given file —
# providing it still exists
oo::define Store method Update {message adding args} {
    set filenames [list]
    foreach filename $args {
        if {[file isfile $filename]} {
            lappend filenames $filename
        } else {
            {*}$Reporter "skipped missing or non-file \"$filename\""
        }
    }
    if {[llength $filenames] == 0} {
        {*}$Reporter "no files to update"
        return 0
    }
    $Db eval {INSERT INTO Generations (message) VALUES ($message)}
    set gid [$Db last_insert_rowid]
    {*}$Reporter "created generation #$gid"
    set n 0
    foreach filename [lsort -nocase $filenames] {
        incr n [my UpdateOne $adding $gid $filename]
    }
    return $n
}

# adds the given file as 'U' or 'Z' or 'S'; returns 1 for 'U' or 'Z' or
# 1 for 'S'
oo::define Store method UpdateOne {adding gid filename} {
    set added 1
    set fileData [FileData load $gid $filename]
    set data [$fileData data]
    set oldGid [my FindMatch $gid $filename $data]
    if {$oldGid != ""} {
        set kind S
        set pgid $oldGid
        set data ""
        set added 0
    } else {
        set kind [$fileData kind]
        set pgid [$fileData pgid]
    }
    set usize [$fileData usize]
    set zsize [$fileData zsize]
    $Db eval {INSERT INTO Files \
        (gid, filename, kind, usize, zsize, pgid, data) VALUES \
        (:gid, :filename, :kind, :usize, :zsize, :pgid, :data)}
    set action [expr {$adding ? "added" : "updated"}]
    switch $kind {
        S { {*}$Reporter "unchanged \"$filename\"" }
        U { {*}$Reporter "$action \"$filename\"" }
        Z { {*}$Reporter "$action \"$filename\" (compressed)" }
    }
    return $added
}

oo::define Store method FindMatch {gid filename data} {
    return [$Db eval {
        SELECT gid FROM Files \
        WHERE filename = :filename AND kind IN ('U', 'Z') AND data = :data
            AND gid != :gid
        ORDER BY gid DESC LIMIT 1
    }]
}

# extracts all files at last or given gid into the current dir or only
# the specified files, in both cases using the naming convention
# path/filename1.ext → path/filename1#gid.ext etc
oo::define Store method extract {{gid 0} args} {
    if {$gid == 0} { set gid [my last_generation] }
    # TODO
    puts "TODO extract"
}

# restore all files at the last or given gid into the current dir or
# the specified files using their original names _overwriting_ the
# current versions; if _any_ of the files to be overwritten has
# unstored changes, does _nothing_ and reports the problem
oo::define Store method restore {{gid 0} args} {
    if {$gid == 0} { set gid [my last_generation] }
    # TODO
    puts "TODO restore"
}

# returns a list of the last or given gid's filenames
oo::define Store method filenames {{gid 0}} {
    if {$gid == 0} { set gid [my last_generation] }
    return [$Db eval {SELECT filename FROM Files WHERE gid = $gid \
            ORDER BY LOWER(filename)}]
}

# lists all generations (gid x created x tag)
oo::define Store method list {} {
    # TODO
    puts "TODO list"
}

# deletes the given filename in every generation
oo::define Store method purge {filename} {
    # TODO
    puts "TODO purge"
}
