# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create FileSize {
    variable Filename ""
    variable Size 0

    constructor {filename size} {
        set Filename $filename 
        set Size $size 
    }

    method filename {} { return $Filename }
    method size {} { return $Size }
    method to_string {} { return "FileSize \"$Filename\" $Size" }
}
