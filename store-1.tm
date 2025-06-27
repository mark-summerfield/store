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
    set Db [self]#DB
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
    $Db eval {INSERT INTO Generations (message) VALUES (:message)}
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
        S { {*}$Reporter "same as generation #$pgid \"$filename\"" }
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

# lists all generations (gid x created x message)
oo::define Store method generations {} {
    return [$Db eval { SELECT gid, created, message FROM ViewGenerations }]
}

# returns a list of the last or given gid's filenames
oo::define Store method filenames {{gid 0}} {
    if {$gid == 0} { set gid [my last_generation] }
    return [$Db eval {SELECT filename FROM Files WHERE gid = :gid \
            ORDER BY LOWER(filename)}]
}

# deletes the given filename in every generation and returns the number
# of records deleted (which could be zero)
oo::define Store method purge {filename} {
    $Db eval {DELETE FROM Files WHERE filename = :filename}
    return [$Db changes]
}

# extracts all files at last or given gid into the current dir or only
# the specified files, in both cases using the naming convention
# path/filename1.ext → path/filename1#gid.ext,
# path/filename2 → path/filename2#gid, etc
oo::define Store method extract {{gid 0} args} {
    if {$gid == 0} { set gid [my last_generation] }
    set filenames [expr {[llength $args] ? $args : [my filenames $gid]}]
    foreach filename $filenames {
        my ExtractOne extracted $gid $filename $filename
    }
}

# restore all files at last or given gid into the given folder
oo::define Store method restore {{gid 0} folder} {
    set filenames [my filenames $gid]
    foreach filename $filenames {
        my ExtractOne restored $gid $filename [file join $folder $filename]
    }
}

oo::define Store method ExtractOne {action gid filename target} {
    lassign [$Db eval {SELECT kind, pgid FROM Files WHERE gid = :gid \
                       AND filename = :filename}] kind pgid
    if {$kind eq "S"} {
        lassign [$Db eval {SELECT kind, data FROM Files WHERE gid = :pgid \
                           AND filename = :filename}] kind data
        set gid $pgid
    } else {
        lassign [$Db eval {SELECT kind, data FROM Files WHERE gid = :gid \
                           AND filename = :filename}] kind data
    }
    if {$kind eq "Z"} { set data [zlib inflate $data] }
    set target [prepare_target $action $gid $target]
    writeFile $target binary $data
    {*}$Reporter "$action \"$filename\" → \"$target\""
}


proc prepare_target {action gid filename} {
    if {$action eq "extracted"} {
        set ext [file extension $filename]
        set target "[file rootname $filename]#$gid$ext"
    } else {
        set target $filename
    }
    set dirname [file dirname $target]
    if {![file isdirectory $dirname]} { file mkdir $dirname }
    return $target
}
