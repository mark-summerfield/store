# Copyright © 2025 Mark Summerfield. All rights reserved.

package require misc
package require sqlite3 3

oo::class create Store {
    variable filename
    variable db

    constructor filename_ {
        variable filename
        set filename $filename_
        set exists [file isfile $filename]
        variable db
        set db ::STORE#[clock clicks]
        sqlite3 $db $filename
        $db eval [misc::read_file $::APPPATH/sql/prepare.sql] 
        if {!$exists} {
            $db eval [misc::read_file $::APPPATH/sql/create.sql] 
            $db eval [misc::read_file $::APPPATH/sql/insert.sql] 
        }
    }

    destructor { my close }

    method close {} {
        if {![my is_closed]} {
            variable db
            $db close
            set db {}
        }
    }

    method is_closed {} {
        variable db
        catch {$db version}
    }
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
