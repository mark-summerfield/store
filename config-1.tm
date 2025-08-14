# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require ui

oo::class create Config {
    variable Filename
    variable Geometry
    variable FontSize
    variable FontFamily
}

oo::define Config constructor {{filename ""} {geometry ""}} {
    set Filename $filename
    set Geometry $geometry
    set FontSize [expr {2 + [font configure TkFixedFont -size]}]
    set FontFamily [font configure TkFixedFont -family]
}

oo::define Config classmethod load {} {
    set filename [ui::get_ini_filename]
    set config [Config new]
    $config filename $filename
    if {[file exists $filename] && [file size $filename]} {
        set ini [ini::open $filename -encoding utf-8 r]
        try {
            $config geometry [ini::value $ini Window Geometry \
                                [$config geometry]]
            $config fontsize [ini::value $ini Window FontSize \
                                [$config fontsize]]
            $config fontfamily [ini::value $ini Window FontFamily \
                                [$config fontfamily]]
        } finally {
            ini::close $ini
        }
    }
    return $config
}

oo::define Config method save {} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini Window Geometry [wm geometry .]
        ini::set $ini Window FontSize [my fontsize]
        ini::set $ini Window FontFamily [my fontfamily]
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {{filename ""}} {
    if {$filename ne ""} { set Filename $filename }
    return $Filename
}

oo::define Config method geometry {{geometry ""}} {
    if {$geometry ne ""} { set Geometry $geometry }
    return $Geometry
}

oo::define Config method fontsize {{fontsize 0}} {
    if {$fontsize > 0} { set FontSize $fontsize }
    return $FontSize
}

oo::define Config method fontfamily {{fontfamily ""}} {
    if {$fontfamily ne ""} { set FontFamily $fontfamily }
    return $FontFamily
}

oo::define Config method to_string {} {
    return "Config filename=$Filename geometry=$Geometry fontsize=$FontSize"
}
