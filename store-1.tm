# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals
package require misc
package require sqlite3 3

oo::class create Store {
    initialize {
        variable Feedback $::FEEDBACK_NONE
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
    $Db eval [misc::read_utf8 $::APPPATH/sql/prepare.sql] 
    if {!$exists} {
        $Db eval [misc::read_utf8 $::APPPATH/sql/create.sql] 
        $Db eval [misc::read_utf8 $::APPPATH/sql/insert.sql] 
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

# creates new generation with 'R' or 'r' or '=' for every given file
# returns the number of files added
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
# 'R' or 'r' or '=' for every file present in the _last_ generation that
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

# creates new generation with 'R' or 'r' or '=' for every given file —
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
    foreach filename $filenames {
        incr n [my UpdateOne $gid $filename]
    }
    return 
}

# adds the given file as 'R' or 'r' or '='; returns 1 for 'R' or 'r' or
# 0 for '='
oo::define Store method UpdateOne {gid filename} {
    puts "TODO Update"
    # TODO report action according to Feedback
    return 0
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
oo::define Store method extract {{gid end} args} {
    puts "TODO extract"
}

# restore all files at the last or given gid into the current dir or
# the specified files using their original names _overwriting_ the
# current versions; if _any_ of the files to be overwritten has
# unstored changes, does _nothing_ and reports the problem
oo::define Store method restore {{gid end} args} {
    puts "TODO restore"
}

# returns a list of the last or given gid's filenames
oo::define Store method filenames {{gid end}} {
    if {$gid eq end} { set gid [my last_generation] }
    set filenames [list]
    $Db eval {SELECT filename FROM Files WHERE gid = $gid \
              ORDER BY LOWER(filename)} {
        lappend filenames $filename
    }
    return $filenames
}

# lists all generations (gid x created x tag)
oo::define Store method list {} {
    puts "TODO list"
}

# returns all excludes (dirname x pattern)
oo::define Store method excludes {} {
    puts "TODO exclude"
}

# adds the given (dirname x pattern) to the excludes
oo::define Store method exclude {dirname pattern} {
    puts "TODO exclude"
}

# removes the given (dirname x pattern) to the excludes
oo::define Store method unexclude {dirname pattern} {
    puts "TODO drop"
}

# deletes the given filename in every generation and adds the filename
# to the excludes (use this for unintentionally stored files)
oo::define Store method purge {filename} {
    puts "TODO purge"
}
