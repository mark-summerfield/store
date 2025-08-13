# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval ui {}

proc ui::wishinit {} {
    catch {
        set fh [open [file join [file home] .wishinit.tcl]]
        set raw [read $fh]
        close $fh
        eval $raw
    }
    const ::LINEHEIGHT [expr {[font metrics font -linespace] * 1.0125}]
    ttk::style configure Treeview -rowheight $::LINEHEIGHT
    set font [font create -family [font actual TkDefaultFont -family] \
                -size [font actual TkDefaultFont -size]]
    ttk::style configure Treeview.Heading -font $font
    ttk::style configure TCheckbutton -indicatorsize \
        [expr {$::LINEHEIGHT * 0.75}]
    set ::ICON_SIZE [expr {max(24, round(20 * [tk scaling]))}]
    set ::MENU_ICON_SIZE [expr {max(20, round(14 * [tk scaling]))}]
}

proc ui::icon {svg {width 0}} {
    if {!$width} {
        return [image create photo -file $::APPPATH/images/$svg]
    }
    image create photo -file $::APPPATH/images/$svg \
        -format "svg -scaletowidth $width"
}

proc ui::get_ini_filename {} {
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

proc ui::open_webpage url {
    if {[tk windowingsystem] eq "win32"} {
        set cmd [list {*}[auto_execok start] {}]
    } else {
        set cmd [auto_execok xdg-open]
    }
    try {
        exec {*}$cmd $url &
    } on error {err} {
        puts "failed to open $url: $err"
    }
}

proc ui::n_s size {
    if {!$size} { return [list "no" "s"] }
    if {$size == 1} { return [list "one" ""] }
    list $size "s"
}

proc ui::human_size {value {suffix B}} {
    if {!$value} {
        return "$value $suffix"
    }
    set factor 1
    if {$value < 0} {
        set factor -1
        set value [expr {$value * $factor}]
    }

    set log_n [expr {int(log($value) / log(1024))}]
    set prefix [lindex [list "" "Ki" "Mi" "Gi" "Ti" "Pi" "Ei" "Zi" "Yi"] \
        $log_n]
    set value [expr {$value / (pow(1024, $log_n))}]
    set value [expr {$value * $factor}]
    set dp [expr {$log_n < 2 ? 0 : 1}]
    return "[format %.${dp}f $value] ${prefix}${suffix}"
}

# which must be one of: vertical horizontal both
# usage:
#    set frame [ttk::frame …]
#    set name _widget_
#    ttk::_widget_ $frame.$name -opts…
#    ui::scrollize $frame $name vertical
#  
proc ui::scrollize {frame name which} {
    package require autoscroll 1

    grid $frame.$name -row 0 -column 0 -sticky news
    if {$which eq "vertical" || $which eq "both"} {
        $frame.$name configure -yscrollcommand "$frame.scrolly set"
        ttk::scrollbar $frame.scrolly -orient vertical \
            -command "$frame.${name} yview"
        grid $frame.scrolly -row 0 -column 1 -sticky ns
        autoscroll::autoscroll $frame.scrolly
    }
    if {$which eq "horizontal" || $which eq "both"} {
        $frame.$name configure -xscrollcommand "$frame.scrollx set"
        ttk::scrollbar $frame.scrollx -orient horizontal \
            -command "$frame.${name} xview"
        grid $frame.scrollx -row 1 -column 0 -sticky we
        autoscroll::autoscroll $frame.scrollx
    }
    grid columnconfigure $frame 0 -weight 1
    grid rowconfigure $frame 0 -weight 1
}
