# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create FileData {
    variable Gid
    variable Filename
    variable Kind
    variable Usize
    variable Zsize
    variable Pgid
    variable Data
}

oo::define FileData constructor {{gid 0} {filename ""} {kind ""} {usize 0} \
        {zsize 0} {pgid 0} {data ""}} {
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

oo::define FileData method gid {} { return $Gid }
oo::define FileData method set_gid {gid} { set Gid $gid }

oo::define FileData method filename {} { return $Filename }
oo::define FileData method set_filename {filename} {
    set Filename $filename
}

oo::define FileData method kind {} { return $Kind }
oo::define FileData method set_kind {kind} { set Kind $kind }

oo::define FileData method usize {} { return $Usize }
oo::define FileData method set_usize {usize} { set Usize $usize }

oo::define FileData method zsize {} { return $Zsize }
oo::define FileData method set_zsize {zsize} { set Zsize $zsize }

oo::define FileData method pgid {} { return $Pgid }
oo::define FileData method set_pgid {pgid} { set Pgid $pgid }

oo::define FileData method data {} { return $Data }
oo::define FileData method set_data {data} { set Data $data }

# for debugging
oo::define FileData method to_string {} {
    return "FileData Gid=$Gid Filename=$Filename Kind=$Kind Usize=$Usize \
            Zsize=$Zsize Pgid=$Pgid Data(len)=[string length $Data]"
}
