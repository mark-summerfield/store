# Copyright © 2025 Mark Summerfield. All rights reserved.

package require db
package require filedata
package require fileutil 1
package require lambda 1
package require misc
package require sqlite3 3
package require util

oo::class create Store {
    variable Filename
    variable Db
    variable Reporter
}

oo::define Store initialize {
    variable VERSION

    const VERSION 1.7.2
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
    $Db transaction {
        if {$exists} {
            set user_version [$Db eval {PRAGMA USER_VERSION}]
            if {$user_version == 1} {
                $Db eval [readFile $::APPPATH/sql/upgrade1to2.sql] 
            }
            if {$user_version == 1 || $user_version == 2} {
                $Db eval [readFile $::APPPATH/sql/upgrade2to3.sql] 
            }
        } else {
            $Db eval [readFile $::APPPATH/sql/create.sql] 
            $Db eval [readFile $::APPPATH/sql/insert.sql] 
        }
    }
}

oo::define Store destructor {
    $Db eval {VACUUM;}
    $Db close
}

oo::define Store method filename {} { return $Filename }

oo::define Store method version {} {
    classvariable VERSION
    return "${VERSION}#[$Db eval {PRAGMA USER_VERSION}]"
}

oo::define Store method current_generation {} {
    $Db eval {SELECT gid FROM CurrentGeneration}
}

oo::define Store method gid_for_tag tag {
    set gid [$Db eval {SELECT gid FROM Generations
                        WHERE tag = :tag LIMIT 1}]
    expr {$gid eq "" ? 0 : $gid}
}

# Creates new generation with 'U' or 'Z' or 'S' for every given file and
# returns the number of files added. Skips already tracked files.
# Note that ignores should be handled by the application itself.
oo::define Store method add args {
    const cwd [pwd]
    set filenames [lsort -dictionary [my filenames]]
    foreach filename $args {
        set filename [fileutil::relative $cwd [file normalize $filename]]
        if {[lsearch -sorted -dictionary -exact $filenames $filename]
                == -1} {
            lappend filenames $filename
        }
    }
    if {![llength $filenames]} { return 0 }
    {*}$Reporter "adding/updating"
    my Update "" {*}$filenames
}

# if at least one prev generation exists, creates new generation with
# 'U' or 'Z' or 'S' for every file present in the current generation that
# hasn't been deleted and returns the number updated (which could be 0);
# must only be used after at least one call to add
oo::define Store method update {tag} {
    set gid [my current_generation]
    if {!$gid} { error "can only update an existing nonempty store" }
    if {$tag ne ""} { {*}$Reporter "updating with tag \"$tag\"" }
    my Update $tag {*}[my filenames $gid]
}

# returns whether the given tag is valid: not an integer & unique
oo::define Store method validtag {tag} {
    if {[string is integer -strict $tag]} {
        return 0
    }
    expr {![llength [$Db eval {SELECT gid FROM Generations
                                WHERE tag = :tag LIMIT 1}]]}
}

# gets or sets or deletes (if tag is "-") a tag for the given or current gid
oo::define Store method tag {{gid 0} {tag ""}} {
    if {!$gid} { set gid [my current_generation] }
    if {$tag eq "-"} {
        $Db eval {UPDATE Generations SET tag = NULL WHERE gid = :gid}
    } elseif {[string is integer -strict $tag]} {
        error "tags may not be integers; got $tag"
    } elseif {$tag ne ""} {
        $Db eval {UPDATE Generations SET tag = :tag WHERE gid = :gid}
    }
    $Db onecolumn {SELECT tag FROM Generations WHERE gid = :gid}
}

# removes a tag for the given or current gid
oo::define Store method untag {{gid 0}} {
    if {!$gid} { set gid [my current_generation] }
    $Db eval {UPDATE Generations SET tag = NULL WHERE gid = :gid}
}

# creates new generation with 'U' or 'Z' or 'S' for every given file —
# providing it still exists
oo::define Store method Update {tag args} {
    const cwd [pwd]
    set filenames [list]
    foreach filename $args {
        set filename [fileutil::relative $cwd [file normalize $filename]]
        if {[file isfile $filename]} {
            lappend filenames $filename
        } elseif {[my find_gid_for_untracked $filename]} {
            {*}$Reporter "skipped untracked file \"$filename\""
        } else {
            {*}$Reporter "skipped missing or nonfile \"$filename\""
        }
    }
    if {![llength $filenames]} {
        {*}$Reporter "no files to update"
        return 0
    }
    $Db transaction {
        $Db eval {INSERT INTO Generations (tag) VALUES (:tag)}
        set gid [$Db last_insert_rowid]
        {*}$Reporter "created @$gid"
        set n 0
        foreach filename [lsort -nocase $filenames] {
            incr n [my UpdateOne $gid $filename]
        }
    }
    return $n
}

# adds the given file as 'U' or 'Z' or 'S'; returns 1 for 'U' or 'Z' or
# 0 for 'S'
oo::define Store method UpdateOne {gid filename} {
    set fileData [FileData load $gid $filename]
    set data [$fileData data]
    set oldGid [my FindMatch $gid $filename $data]
    if {$oldGid} {
        set kind S
        set pgid $oldGid
        set sql {INSERT INTO Files (gid, filename, kind, pgid) VALUES
                 (:gid, :filename, :kind, :pgid)}
    } else {
        set kind [$fileData kind]
        set pgid [$fileData pgid]
        set usize [$fileData usize]
        set zsize [$fileData zsize]
        set sql {INSERT INTO Files 
                 (gid, filename, kind, usize, zsize, pgid, data) VALUES
                 (:gid, :filename, :kind, :usize, :zsize, :pgid, :data)}
    }
    $Db transaction {
        $Db eval {DELETE FROM Ignores WHERE pattern = :filename}
        set updated [$Db eval {SELECT EXISTS(SELECT filename FROM FILES
                                             WHERE filename = :filename)}]
        $Db eval $sql
    }
    set action [expr {$updated ? "updated" : "added  "}]
    switch $kind {
        S { {*}$Reporter "same as @$pgid \"$filename\"" }
        Z -
        U { {*}$Reporter "$action \"$filename\"" }
    }
    expr {!$updated} ;# not updated → added
}

oo::define Store method FindMatch {gid filename data} {
    set gid [$Db onecolumn {
        SELECT gid FROM Files
        WHERE filename = :filename AND kind != 'S' AND data = :data
              AND gid != :gid
        ORDER BY gid DESC LIMIT 1
    }]
    expr {$gid ne {} ? $gid : 0}
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
}

# lists gid's: filters are: all, untagged, tagged
oo::define Store method gids {{filter all}} {
    switch $filter {
        all {set where ""}
        untagged {set where " WHERE tag IS NULL OR LENGTH(tag) = 0"}
        tagged {set where " WHERE tag IS NOT NULL AND LENGTH(tag) > 0"}
    }
    $Db eval "SELECT gid FROM Generations$where ORDER BY gid DESC"
}

# lists all generations (gid, created) or full (gid, created, tag)
oo::define Store method generations {{full 0}} {
    if {$full} {
        return [$Db eval {SELECT gid, created, tag, filename
                          FROM HistoryByGeneration}]
    }
    $Db eval {SELECT gid, created, tag FROM ViewGenerations}
}

# returns a list of the current or given gid's filenames
oo::define Store method filenames {{gid 0}} {
    if {!$gid} { set gid [my current_generation] }
    $Db eval {SELECT filename FROM Files WHERE gid = :gid
              ORDER BY LOWER(filename)}
}

# returns 1 if the filename is in the current generation; otherwise 0
oo::define Store method is_current filename {
    set gid [my current_generation]
    $Db eval {SELECT EXISTS(SELECT filename FROM Files WHERE gid = :gid
              AND filename = :filename LIMIT 1)}
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
    lassign [util::n_s $nfiles] nf ns
    lassign [util::n_s $ngens] gf gs
    {*}$Reporter "cleaned $nf file$ns in $gf generation$gs"
}

# the current generation—even if empy—is never cleanable
oo::define Store method needs_clean {} {
    $Db eval {SELECT COUNT(*) FROM EmptyGenerations
                WHERE gid NOT IN CurrentGeneration;}
}

oo::define Store method untracked {{filename ""}} {
    if {$filename ne ""} {
        return [$Db eval {SELECT EXISTS(SELECT filename FROM Untracked
                                        WHERE filename = :filename)}]
    }
    $Db eval {SELECT filename FROM Untracked}
}

# deletes the given filename in every generation and returns the number
# of records deleted (which could be 0)
oo::define Store method purge {filename} {
    $Db eval {DELETE FROM Files WHERE filename = :filename}
    set n [$Db changes]
    return $n
}

# extracts all files at current or given gid into the current dir or only
# the specified files, in both cases using the naming convention
# path/filename1.ext → path/filename1@gid.ext,
# path/filename2 → path/filename2@gid, etc
oo::define Store method extract {{gid 0} args} {
    if {!$gid} { set gid [my current_generation] }
    set filenames [expr {[llength $args] ? $args : [my filenames $gid]}]
    foreach filename $filenames {
        my ExtractOne extracted $gid $filename $filename
    }
}

# extracts the given file from the current generation overwriting the
# original
oo::define Store method restore {args} {
    set gid [my current_generation]
    set tempdir [fileutil::tempdir]
    foreach filename $args {
        catch { file rename $filename [file join $tempdir $filename] }
        my ExtractOne restored $gid $filename $filename
    }
}

# copy all files at current or given gid into the given folder (which
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
    set extra ""
    if {!$gid} {
        set gid [my find_gid_for_untracked $filename]
        lassign [my get $gid $filename] gid data
        set extra " (no longer tracked)"
    }
    if {!$gid} {
        {*}$Reporter "failed to find \"$filename\" in the store"
        return
    }
    set target [my PrepareTarget $action $gid $target]
    writeFile $target binary $data
    {*}$Reporter "$action \"$filename\"$extra → \"$target\""
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
            WHERE filename = :filename AND kind != 'S'
            ORDER BY gid DESC}]
    }
    $Db eval {SELECT filename, gid FROM HistoryByFilename}
}

oo::define Store method gids_for_filename {filename} {
    $Db eval {SELECT '@' || gid FROM Files
              WHERE filename = :filename AND kind != 'S'
              ORDER BY gid DESC}
}

# Returns the gid for the given filename at the given gid; The
# returned gid will equal the given gid if the data is U or Z or will be the
# pgid where the data is U or Z if the data at the given gid is S
oo::define Store method find_data_gid {gid filename} {
    lassign [$Db eval {SELECT kind, pgid FROM Files
                WHERE gid = :gid AND filename = :filename}] kind pgid
    if {$kind eq ""} { return 0 } ;# not found
    expr {$kind eq "S" ? $pgid : $gid}
}

oo::define Store method find_gid_for_untracked {filename} {
    set gid [$Db eval {SELECT gid FROM Files WHERE filename = :filename
                       AND kind != 'S' ORDER BY gid DESC LIMIT 1}]
    expr {$gid eq "" ? 0 : $gid}
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

oo::define Store method is_same_on_disk {filename} {
    if {![file exists $filename]} {
        return 0 ;# not on disk
    }
    $Db transaction {
        set gid [$Db eval {SELECT gid FROM CurrentGeneration}]
        set dgid [my find_data_gid $gid $filename]
        if {!$dgid} {
            return 0 ;# not in store
        }
        set usize [$Db eval {SELECT usize FROM Files WHERE gid = :dgid
                             AND filename = :filename}]
        if {$usize != [file size $filename]} {
            return 0 ;# different sizes
        }
        set disk_data [readFile $filename binary]
        lassign [$Db eval {SELECT kind, data FROM Files WHERE gid = :dgid
                           AND filename = :filename}] kind data
        if {$kind eq "Z"} { set data [zlib inflate $data] }
        return [expr {$data eq $disk_data}] ;# same or different data
    }
}

oo::define Store method addable {} {
    set candidates [my candidates_from_given [glob -types f * */*]]
    set gid [my current_generation]
    lsort -unique [lmap name $candidates { ;# drop already stored files
        expr {[my find_data_gid $gid $name] ? [continue] : $name}
    }]
}

oo::define Store method updatable {} {
    set candidates [list]
    foreach filename [my filenames] {
        if {![my is_same_on_disk $filename]} {
            lappend candidates $filename
        }
    }
    return $candidates
}

oo::define Store method have_updates {} {
    foreach filename [my filenames] {
        if {![my is_same_on_disk $filename]} { return 1 }
    }
    return 0
}

# we deliberately only go at most one level deep for folders
oo::define Store method candidates_from_given {candidates} {
    set ignores [my ignores]
    set names [list]
    foreach name $candidates {
        if {![misc::ignore $name $ignores]} {
            if {[file isdirectory $name]} {
                foreach subname [glob -directory $name -types f *] {
                    if {![misc::ignore $subname $ignores] &&
                            [misc::valid_file $subname]} {
                        lappend names $subname   
                    }
                }
            } elseif {[misc::valid_file $name]} {
                lappend names $name
            }
        }
    }
    lsort -unique $names
}

oo::define Store method to_string {} { return "Store \"$Filename\"" }
