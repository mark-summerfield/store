# Copyright © 2025 Mark Summerfield. All rights reserved.

package require globals
package require sqlite3 3

oo::class create FileRecord {
    variable Gid 0
    variable Filename ""
    variable Kind ""
    variable Usize 0
    variable Zsize 0
    variable Pgid 0
    variable Data ""
}

oo::define FileRecord constructor {{gid 0} {filename ""} {kind ""} \
        {usize 0} {zsize 0} {pgid 0} {data ""}} {
    set Gid $gid 
    set Filename $filename 
    set Kind $kind 
    set Usize $usize 
    set Zsize $zsize 
    set Pgid $pgid 
    set Data $data 
}

oo::define FileRecord method is_valid {} {
    return [string match [UZ=] $Kind]
}

oo::define FileRecord method load {filename} {
    set Filename $filename
    set udata [readFile $Filename binary]
    set Usize [string length $udata]
    set zdata [zlib compress $Data 9]
    set Zsize [string length $zdata]
    if {$Usize <= $Zsize} {
        set Data $udata
        set Zsize 0
        set Kind $::KIND_UNCOMPRESSED
    } else {
        set Data $zdata
        set Kind $::KIND_ZLIB_COMPRESSED
    }
}

oo::define FileRecord method gid {{gid 0}} {
    if {$gid != 0} {
        set Gid $gid
    }
    return $Gid
}

oo::define FileRecord method filename {{filename ""}} {
    if {$filename ne ""} {
        set Filename $filename
    }
    return $Filename
}

oo::define FileRecord method kind {{kind ""}} {
    if {$kind ne ""} {
        set Kind $kind
        if {$Kind eq $::KIND_SAME_AS_PREV} {
            set Data ""
        }
    }
    return $Kind
}

oo::define FileRecord method usize {{usize 0}} {
    if {$usize != 0} {
        set Usize $usize
    }
    return $Usize
}

oo::define FileRecord method zsize {{zsize 0}} {
    if {$zsize != 0} {
        set Zsize $zsize
    }
    return $Zsize
}

oo::define FileRecord method pgid {{pgid 0}} {
    if {$pgid != 0} {
        set Pgid $pgid
    }
    return $Pgid
}

oo::define FileRecord method data {{data ""}} {
    if {$data ne ""} {
        set Data $data
    }
    return $Data
}
