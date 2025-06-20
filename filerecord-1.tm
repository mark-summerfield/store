# Copyright © 2025 Mark Summerfield. All rights reserved.

package require sqlite3 3

oo::class create FileRecord {
    variable Gid
    variable Filename
    variable Kind
    variable Usize
    variable Zsize
    variable Pgid
    variable Data
}

oo::define FileRecord constructor {db gid filename} {
    $db eval {SELECT gid, filename, kind, usize, zsize, pgid, data \
              FROM Files WHERE gid = :gid AND filename = :filename} {
        set Gid $gid 
        set Filename $filename 
        set Kind $kind 
        set Usize $usize 
        set Zsize $zsize 
        set Pgid $pgid 
        set Data $data 
    }
}

oo::define FileRecord method gid {} { return $Gid }
oo::define FileRecord method filename {} { return $Filename }
oo::define FileRecord method kind {} { return $Kind }
oo::define FileRecord method usize {} { return $Usize }
oo::define FileRecord method zsize {} { return $Zsize }
oo::define FileRecord method pgid {} { return $Pgid }
oo::define FileRecord method data {} { return $Data }
