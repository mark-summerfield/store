# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::singleton create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable FontFamily
    variable FontSize
}

oo::define Config constructor {} {
    set Geometry "1024x800"
    set Blinking true
    set FontFamily [font configure TkFixedFont -family]
    set FontSize [expr {2 + [font configure TkFixedFont -size]}]
    set Filename [util::get_ini_filename]
    if {[file exists $Filename] && [file size $Filename]} {
        set ini [ini::open $Filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale [tk scaling]]
            set Blinking [ini::value $ini General Blinking $Blinking]
            if {!$Blinking} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            set Geometry [ini::value $ini General Geometry $Geometry]
            set FontFamily [ini::value $ini General FontFamily $FontFamily]
            set FontSize [ini::value $ini General FontSize $FontSize]
        } on error err {
            puts "invalid config in '$Filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Blinking [my blinking]
        ini::set $ini General Geometry [wm geometry .]
        ini::set $ini General FontFamily [my fontfamily]
        ini::set $ini General FontSize [my fontsize]
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method blinking {} { return $Blinking }
oo::define Config method set_blinking blinking { set Blinking $blinking }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method fontsize {} { return $FontSize }
oo::define Config method set_fontsize fontsize { set FontSize $fontsize }

oo::define Config method fontfamily {} { return $FontFamily }
oo::define Config method set_fontfamily fontfamily {
    set FontFamily $fontfamily
}

oo::define Config method to_string {} {
    return "Config filename=$Filename scaling=[tk scaling]\
        geometry=$Geometry fontfamily=$FontFamily fontsize=$FontSize\
        blinking=$Blinking"
}
