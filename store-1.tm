# Copyright © 2025 Mark Summerfield. All rights reserved.

package require filedata
package require globals
package require misc
package require sqlite3 3

oo::class create Store {
    initialize {
        variable Verbose false
    }
    variable Filename
    variable Db
}

oo::define Store classmethod set_verbose verbose {
    my variable Verbose
    set Verbose $verbose
}

oo::define Store classmethod verbose {} {
    my variable Verbose
    return $Verbose
}

# creates database if it doesn't exist
oo::define Store constructor filename {
    set Filename $filename
    set exists [file isfile $Filename]
    set Db ::STR#[string range [clock clicks] end-8 end]
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

# Creates new generation with 'U' or 'Z' or '=' for every given file
# returns the number of files added. (Excludes should be handled by the
# application itself.)
oo::define Store method add {args} {
    set size [llength $args]
    set n [expr {$size == 1 ? "one" : $size}]
    set s [expr {$size == 1 ? "" : "s"}]
    if {[my verbose]} { puts "adding $n new file$s" }
    return [my Update "added $n new file$s" true {*}$args]
}

# if at least one prev generation exists, creates new generation with
# 'U' or 'Z' or '=' for every file present in the _last_ generation that
# hasn't been deleted and returns the number updated; otherwise does
# nothing and returns 0
oo::define Store method update {message} {
    set gid [my last_generation]
    if {$gid == 0} { return 0 }
    if {[my verbose]} { puts "updating: $message" }
    return [my Update $message false {*}[my filenames $gid]]
}

# creates new generation with 'U' or 'Z' or '=' for every given file —
# providing it still exists
oo::define Store method Update {message adding args} {
    set filenames [list]
    foreach filename $args {
        if {[file isfile $filename]} {
            lappend filenames $filename
        } elseif {[my verbose]} {
            puts "skipped missing or non-file \"$filename\""
        }
    }
    if {[llength $filenames] == 0} {
        if {[my verbose]} { puts "no files to update" }
        return 0
    }
    $Db eval {INSERT INTO Generations (message) VALUES ($message)}
    set gid [$Db last_insert_rowid]
    if {[my verbose]} { puts "created generation #$gid" }
    set n 0
    foreach filename $filenames {
        incr n [my UpdateOne $adding $gid $filename]
    }
    return $n
}

# adds the given file as 'U' or 'Z' or '='; returns 1 for 'U' or 'Z' or
# 1 for '='
oo::define Store method UpdateOne {adding gid filename} {
    set added 1
    set oldFileData [my GetMostRecent $filename]
    set fileData [FileData load $gid $filename]
    if {[$oldFileData is_valid] && \
            [$oldFileData kind] eq [$fileData kind] && \
            [$oldFileData data] eq [$fileData data]} {
        $fileData kind $::SAME_AS_PREV
        $fileData pgid [$oldFileData gid]
        $fileData clear_data
        set added 0
    }
    set kind [$fileData kind]
    set usize [$fileData usize]
    set zsize [$fileData zsize]
    set pgid [$fileData pgid]
    set data [$fileData data]
    $Db eval {INSERT INTO Files \
        (gid, filename, kind, usize, zsize, pgid, data) VALUES \
        (:gid, :filename, :kind, :usize, :zsize, :pgid, :data)}
    if {[my verbose]} {
        set action [expr {$adding ? "added" : "updated"}]
        if {$kind eq $::SAME_AS_PREV} {
            puts "unchanged \"$filename\""
        } elseif {$kind eq $::UNCOMPRESSED} {
            puts "$action \"$filename\""
        } elseif {$kind eq $::ZLIB_COMPRESSED} {
            puts "$action \"$filename\" (zlib compressed)"
        }
    }
    return $added
}

oo::define Store method GetMostRecent {filename} {
    set gid [$Db eval {SELECT COALESCE(gid, 0) FROM Files \
                       WHERE filename = :filename \
                       AND kind != $::SAME_AS_PREV}]
    if {$gid != 0} {
        set data [$Db eval {SELECT gid, filename, kind, usize, zsize, \
                            pgid, data FROM Files \
                            WHERE gid = :gid AND filename = :filename}]
        set fileData [FileData new {*}data]
    } else {
        set fileData [FileData new]
    }
    return $fileData
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
