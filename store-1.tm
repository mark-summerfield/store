# Copyright © 2025 Mark Summerfield. All rights reserved.

package require filedata
package require filesize
package require lambda 1
package require misc
package require sqlite3 3

oo::class create Store {
    variable Filename
    variable Db
    variable Reporter
}

# creates database if it doesn't exist; sets reporter to ignore messages
# unless the caller overrides
oo::define Store constructor {filename {reporter ""}} {
    set Filename $filename
    set Reporter [expr {$reporter eq "" ? [lambda {message} {}] \
                                        : $reporter}]
    set Db [self]#DB
    set exists [file isfile $Filename]
    sqlite3 $Db $Filename
    $Db eval [readFile $::APPPATH/sql/prepare.sql] 
    if {!$exists} {
        $Db transaction {
            $Db eval [readFile $::APPPATH/sql/create.sql] 
            $Db eval [readFile $::APPPATH/sql/insert.sql] 
        }
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
    $Db eval {SELECT gid FROM LastGeneration}
}

# creates new generation with 'U' or 'Z' or 'S' for every given file and
# returns the number of files added.
# Note that ignores should be handled by the application itself.
oo::define Store method add {args} {
    set filenames [lsort -nocase \
        [lsort -unique [list {*}[my filenames] {*}$args]]]
    {*}$Reporter "adding/updating"
    my Update "adding/updating" true {*}$filenames
}

# if at least one prev generation exists, creates new generation with
# 'U' or 'Z' or 'S' for every file present in the _last_ generation that
# hasn't been deleted and returns the number updated (which could be 0);
# must only be used after at least one call to add
oo::define Store method update {message} {
    set gid [my last_generation]
    if {!$gid} { error "can only update an existing non-empty store" }
    if {$message ne ""} { {*}$Reporter "updating \"$message\"" }
    my Update $message false {*}[my filenames $gid]
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
    if {![llength $filenames]} {
        {*}$Reporter "no files to update"
        return 0
    }
    $Db transaction {
        $Db eval {INSERT INTO Generations (message) VALUES (:message)}
        set gid [$Db last_insert_rowid]
        {*}$Reporter "created @$gid"
        set n 0
        foreach filename [lsort -nocase $filenames] {
            incr n [my UpdateOne $adding $gid $filename]
        }
    }
    return $n
}

# adds the given file as 'U' or 'Z' or 'S'; returns 1 for 'U' or 'Z' or
# 0 for 'S'
oo::define Store method UpdateOne {adding gid filename} {
    set added 1
    set fileData [FileData load $gid $filename]
    set data [$fileData data]
    set oldGid [my FindMatch $gid $filename $data]
    if {$oldGid} {
        set kind S
        set pgid $oldGid
        set sql {INSERT INTO Files (gid, filename, kind, pgid) VALUES
                 (:gid, :filename, :kind, :pgid)}
        set added 0
    } else {
        set kind [$fileData kind]
        set pgid [$fileData pgid]
        set usize [$fileData usize]
        set zsize [$fileData zsize]
        set sql {INSERT INTO Files 
                 (gid, filename, kind, usize, zsize, pgid, data) VALUES
                 (:gid, :filename, :kind, :usize, :zsize, :pgid, :data)}
    }
    $Db eval $sql
    set action [expr {$adding ? "added" : "updated"}]
    switch $kind {
        S { {*}$Reporter "same as @$pgid \"$filename\"" }
        U { {*}$Reporter "$action \"$filename\"" }
        Z { {*}$Reporter "$action \"$filename\" (deflated)" }
    }
    return $added
}

oo::define Store method FindMatch {gid filename data} {
    set gid [$Db eval {
        SELECT gid FROM Files
        WHERE filename = :filename AND kind IN ('U', 'Z') AND data = :data
              AND gid != :gid
        ORDER BY gid DESC LIMIT 1
    }]
    expr {$gid eq "" ? 0 : $gid}
}

# returns the filenames, dirnames, and globs to ignore
oo::define Store method ignores {} {
    $Db eval {SELECT pattern FROM Ignores ORDER BY LOWER(pattern)}
}

# add filenames or dirnames or globs to ignore;
# note that hidden files are ignored by default so need not be added
oo::define Store method ignore {args} {
    $Db transaction {
        foreach pattern $args {
            $Db eval {INSERT OR REPLACE INTO Ignores (pattern)
                      VALUES (:pattern)}
        }
    }
}

# delete filenames or dirnames or globs to ignore
oo::define Store method unignore {args} {
    $Db transaction {
        foreach pattern $args {
            $Db eval {DELETE FROM Ignores WHERE pattern = :pattern}
        }
    }
    $Db eval {VACUUM;}
}

# lists all generations (gid, created, message)
oo::define Store method generations {{full false}} {
    if {$full} {
        return [$Db eval {SELECT gid, created, message, filename
                          FROM HistoryByGeneration}]
    }
    $Db eval {SELECT gid, created, message FROM ViewGenerations}
}

# returns a list of the last or given gid's filenames
oo::define Store method filenames {{gid 0}} {
    if {!$gid} { set gid [my last_generation] }
    $Db eval {SELECT filename FROM Files WHERE gid = :gid
              ORDER BY LOWER(filename)}
}

# cleans, i.e., deletes, every “empty” generation that has no changes
oo::define Store method clean {} {
    $Db transaction {
        $Db eval {DELETE FROM Files WHERE gid IN (
                    SELECT gid FROM EmptyGenerations);}
        set nfiles [$Db changes]
        $Db eval {DELETE FROM Generations WHERE gid NOT IN (
                    SELECT gid FROM Files);}
        set ngens [$Db changes]
    }
    $Db eval {VACUUM;}
    lassign [misc::n_s $nfiles] nf ns
    lassign [misc::n_s $ngens] gf gs
    {*}$Reporter "cleaned $nf file$ns in $gf generation$gs"
}

oo::define Store method needs_clean {} {
    $Db eval {SELECT COUNT(*) FROM EmptyGenerations;}
}

# deletes the given filename in every generation and returns the number
# of records deleted (which could be 0)
oo::define Store method purge {filename} {
    $Db eval {DELETE FROM Files WHERE filename = :filename}
    set n [$Db changes]
    $Db eval {VACUUM;}
    return $n
}

# extracts all files at last or given gid into the current dir or only
# the specified files, in both cases using the naming convention
# path/filename1.ext → path/filename1@gid.ext,
# path/filename2 → path/filename2@gid, etc
oo::define Store method extract {{gid 0} args} {
    if {!$gid} { set gid [my last_generation] }
    set filenames [expr {[llength $args] ? $args : [my filenames $gid]}]
    foreach filename $filenames {
        my ExtractOne extracted $gid $filename $filename
    }
}

# copy all files at last or given gid into the given folder (which
# must not already exist)
oo::define Store method copy {{gid 0} {folder ""}} {
    if {[file isdirectory $folder]} {
        error "can only copy into a new nonexistent folder"
    }
    set filenames [my filenames $gid]
    foreach filename $filenames {
        my ExtractOne copied $gid $filename [file join $folder $filename]
    }
}

oo::define Store method ExtractOne {action gid filename target} {
    lassign [my get $gid $filename] gid data
    set target [my PrepareTarget $action $gid $target]
    writeFile $target binary $data
    {*}$Reporter "$action \"$filename\" → \"$target\""
}

# Returns the gid and data for the given filename at the given gid; The
# returned gid will equal the given gid if the data is U or Z or will be the
# pgid where the data is U or Z if the data at the given gid is S
oo::define Store method get {gid filename} {
    $Db transaction {
        set gid [my find_data_gid $gid $filename]
        lassign [$Db eval {SELECT kind, data FROM Files
                    WHERE gid = :gid AND filename = :filename}] kind data
    }
    if {$kind eq "Z"} { set data [zlib inflate $data] }
    list $gid $data
}

# returns a list of lines each with a filename and its generations
# of records deleted (which could be 0)
oo::define Store method history {{filename ""}} {
    if {$filename ne ""} {
        return [$Db eval {
            SELECT filename, gid FROM Files
            WHERE filename = :filename AND kind in ('U', 'Z')
            ORDER BY gid DESC}]
    }
    $Db eval {SELECT filename, gid FROM HistoryByFilename}
}

# Returns the file sizes for every file in the last generation (using the
# size from its parent if the file's kind is 'S')
oo::define Store method file_sizes {} {
    set file_sizes [list]
    $Db transaction {
        set gid [$Db eval {SELECT gid FROM LastGeneration}]
        foreach filename [$Db eval {SELECT filename FROM Files
                                    WHERE gid = :gid}] {
            set dgid [my find_data_gid $gid $filename]
            set usize [$Db eval {SELECT usize FROM Files WHERE gid = :dgid
                                 AND filename = :filename}]
            lappend file_sizes [FileSize new $filename $usize]
        }
    }
    return $file_sizes
}

# Returns the gid for the given filename at the given gid; The
# returned gid will equal the given gid if the data is U or Z or will be the
# pgid where the data is U or Z if the data at the given gid is S
oo::define Store method find_data_gid {gid filename} {
    lassign [$Db eval {SELECT kind, pgid FROM Files
                WHERE gid = :gid AND filename = :filename}] kind pgid
    if {$kind eq ""} { return 0 } ;# not found
    expr {$kind eq "S" ? $pgid : $gid} ;# in fact could just return $pgid
}

oo::define Store method PrepareTarget {action gid filename} {
    if {$action eq "extracted"} {
        set ext [file extension $filename]
        set target "[file rootname $filename]@$gid$ext"
    } else {
        set target $filename
    }
    set dirname [file dirname $target]
    if {![file isdirectory $dirname]} { file mkdir $dirname }
    return $target
}
