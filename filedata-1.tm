# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create FileData {
    variable Gid 0
    variable Filename ""
    variable Kind ""
    variable Usize 0
    variable Zsize 0
    variable Pgid 0
    variable Data ""
}

oo::define FileData constructor {{gid 0} {filename ""} {kind ""} \
        {usize 0} {zsize 0} {pgid 0} {data ""}} {
    set Gid $gid 
    set Filename $filename 
    set Kind $kind 
    set Usize $usize 
    set Zsize $zsize 
    set Pgid $pgid 
    set Data $data 
}

oo::define FileData classmethod load {gid filename} {
    set udata [readFile $filename binary]
    set usize [string length $udata]
    set zdata [zlib deflate $udata 9]
    set zsize [string length $zdata]
    if {$usize <= $zsize} {
        set data $udata
        set zsize 0
        set kind U
    } else {
        set data $zdata
        set kind Z
    }
    FileData new $gid $filename $kind $usize $zsize $gid $data
}

oo::define FileData method is_valid {} {
    string match {[UZS]} $Kind
}

oo::define FileData method gid {{gid 0}} {
    if {$gid} { set Gid $gid }
    return $Gid
}

oo::define FileData method filename {{filename ""}} {
    if {$filename ne ""} { set Filename $filename }
    return $Filename
}

oo::define FileData method kind {{kind ""}} {
    if {$kind ne ""} { set Kind $kind }
    return $Kind
}

oo::define FileData method usize {{usize 0}} {
    if {$usize} { set Usize $usize }
    return $Usize
}

oo::define FileData method zsize {{zsize 0}} {
    if {$zsize} { set Zsize $zsize }
    return $Zsize
}

oo::define FileData method pgid {{pgid 0}} {
    if {$pgid} { set Pgid $pgid }
    return $Pgid
}

oo::define FileData method data {{data ""}} {
    if {$data ne ""} { set Data $data }
    return $Data
}

oo::define FileData method clear_data {} { set Data "" }

# for debugging
oo::define FileData method to_string {} {
    return "FileData Gid=$Gid Filename=$Filename Kind=$Kind Usize=$Usize \
            Zsize=$Zsize Pgid=$Pgid Data(len)=[string length $Data]"
}
