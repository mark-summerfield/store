# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval misc {}

proc misc::icon {svg {width 0}} {
    if {!$width} {
        return [image create photo -file $::APPPATH/images/$svg]
    }
    image create photo -file $::APPPATH/images/$svg \
        -format "svg -scaletowidth $width"
}

proc misc::get_ini_filename {} {
    set name [string totitle [tk appname]].ini
    set home [file home]
    if {[tk windowingsystem] eq "win32"} {
        set names [list [file join $home $name] $::APPPATH/$name]
        set index 0
    } else {
        set names [list [file join $home .config/$name] \
                        [file join $home .$name] $::APPPATH/$name]
        set index [expr {[file isdirectory \
                            [file join $home .config]] ? 0 : 1}]
    }
    foreach name $names {
        set name [file normalize $name]
        if {[file exists $name]} {
            return $name
        }
    }
    lindex $names $index
}

proc misc::human_size {value {suffix B} {dp 0}} {
    if {!$value} {
        return "$value $suffix"
    }
    set factor 1
    if {$value < 0} {
        set factor -1
        set value [expr {$value * $factor}]
    }

    set log_n [expr {int( log( $value ) / log(1024) )}]
    set prefix [lindex [list "" "Ki" "Mi" "Gi" "Ti" "Pi" "Ei" "Zi" "Yi"] \
        $log_n]
    set value [expr {$value / (pow(1024, $log_n))}]
    set value [expr {$value * $factor}]
    return "[format %.${dp}f $value] ${prefix}${suffix}"
}
