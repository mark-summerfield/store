# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::class create FileSize {
    variable Filename ""
    variable Size 0
}

oo::define FileSize constructor {filename size} {
    set Filename $filename 
    set Size $size 
}

oo::define FileSize method filename {} { return $Filename }

oo::define FileSize method size {} { return $Size }
