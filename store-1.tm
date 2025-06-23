# Copyright © 2025 Mark Summerfield. All rights reserved.

package require filerecord
package require globals
package require misc
package require sqlite3 3

oo::class create Store {
    initialize {
        variable Feedback $::FEEDBACK_ERRORS
    }
    variable Filename
    variable Db
}

oo::define Store classmethod set_feedback feedback {
    my variable Feedback
    set Feedback $feedback
}

oo::define Store classmethod feedback {} {
    my variable Feedback
    return $Feedback
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
    set n [expr {$size == 1 ? one : $size}]
    set s [expr {$size == 1 ? "" : s}]
    if {[my feedback] eq $::FEEDBACK_FULL} {
        puts "adding $n new file$s"
    }
    return [my Update "added $n new file$s" {*}args]
}

# if at least one prev generation exists, creates new generation with
# 'U' or 'Z' or '=' for every file present in the _last_ generation that
# hasn't been deleted and returns the number updated; otherwise does
# nothing and returns 0
oo::define Store method update {message} {
    set gid [my last_generation]
    if {$gid == 0} { return 0 }
    if {[my feedback] eq $::FEEDBACK_FULL} {
        puts "updating: $message"
    }
    return [my Update $message {*}[my filenames $gid]]
}

# creates new generation with 'U' or 'Z' or '=' for every given file —
# providing it still exists
oo::define Store method Update {message args} {
    set filenames [lmap filename $args {
        expr {[file isfile $filename] ? $filename : [continue]}
    }]
    if {[llength $filenames] == 0} { return 0 }
    $Db eval {INSERT INTO Generations (message) VALUES ($message)}
    set gid [$Db eval {LAST_INSERT_ROWID}]
    if {[my feedback] eq $::FEEDBACK_FULL} {
        puts "created new generation gid=$gid"
    }
    set n 0
    foreach filename $filenames { incr n [my UpdateOne $gid $filename] }
    return $n
}

# adds the given file as 'U' or 'Z' or '='; returns 1 for 'U' or 'Z' or
# 1 for '='
oo::define Store method UpdateOne {gid filename} {
    set added 1
    set oldFileRecord [my GetMostRecent $filename]
    set fileRecord load $filename
    if {[$oldFileRecord is_valid]} {
        if {[$oldFileRecord kind] eq [$fileRecord kind] &&
                [$oldFileRecord data] eq [$fileRecord data]} {
            $fileRecord kind $::KIND_SAME_AS_PREV
            $fileRecord gid [$oldFileRecord gid]
            set added 0
        }
    }
    $fileRecord gid $gid
    # TODO insert fileRecord into Files
    # TODO report action according to Feedback i.e., 'U' or 'Z' or '='
    return $added
}

oo::define Store method GetMostRecent {filename} {
    set gid [$Db eval {SELECT gid FROM Files WHERE filename = :filename \
                       AND kind != '='}]
    if {$gid ne $::NULL} {
        $db eval {SELECT gid, filename, kind, usize, zsize, pgid, data \
                  FROM Files WHERE gid = :gid AND filename = :filename} {
            set fileRecord [FileRecord new $gid $filename $kind $usize \
                            $zsize $pgid $data]
        }
    } else {
        set fileRecord [FileRecord new]
    }
    return $fileRecord
}

# Algorithm for storing a file in a new generation
#
#   if the file is new
#	read file
#	gzip file
#	store R or r into data whichever is smaller
#	set usize and if r set zsize
#   else if the file is in a previous generation
#	read file
#	if prev is R and usize == prev usize and data == prev data
#	    set = and set pgid
#	else
#	    gzip file
#	    if prev is r and zsize == prev zsize and data == prev data
#	        set = and set pgid
#	    else
#	    	store R or r into data whichever is smaller
#	    	set usize and if r set zsize

# extracts all files at last or given gid into the current dir or only
# the specified files, in both cases using the naming convention
# path/filename1.ext → path/filename1#gid.ext etc
oo::define Store method extract {{gid 0} args} {
    # TODO
    puts "TODO extract"
}

# restore all files at the last or given gid into the current dir or
# the specified files using their original names _overwriting_ the
# current versions; if _any_ of the files to be overwritten has
# unstored changes, does _nothing_ and reports the problem
oo::define Store method restore {{gid 0} args} {
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
