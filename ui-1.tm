# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1

namespace eval ui {}

proc ui::wishinit {} {
    option add *tearOff 0
    ttk::style theme use clam
    const ::LINEHEIGHT [expr {[font metrics TkDefaultFont -linespace] \
        * 1.5}]
    ttk::style configure Treeview -rowheight $::LINEHEIGHT
    ttk::style configure Treeview.Heading -font TkDefaultFont
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

# which must be one of: vertical horizontal both
# usage:
#    set frame [ttk::frame …]
#    set name _widget_
#    ttk::_widget_ $frame.$name -opts…
#    ui::scrollize $frame $name vertical
#  
proc ui::scrollize {frame name which} {
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
