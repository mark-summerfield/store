# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ntext 1

namespace eval gui_misc {}

proc gui_misc::icon {svg {width 0}} {
    if {!$width} {
        return [image create photo -file $::APPPATH/images/$svg]
    }
    image create photo -file $::APPPATH/images/$svg \
        -format "svg -scaletowidth $width"
}

proc gui_misc::prepare_form {window on_close {modal true} {x 0} {y 0}} {
    wm withdraw $window
    if {$modal} {
        wm transient $window .
    }
    set parent [winfo parent $window]
    if {!($x && $y)} {
        set x [expr {[winfo x $parent] + [winfo width $parent] / 3}]
        set y [expr {[winfo y $parent] + [winfo height $parent] / 3}]
    }
    wm geometry $window "+$x+$y"
    wm protocol $window WM_DELETE_WINDOW $on_close
    if {$modal} {
        grab $window ;# caller must call: grab release $window
    }
    wm deiconify $window
    raise $window
    focus $window
}

proc gui_misc::make_text_frame {} {
    set textFrame [ttk::frame .textFrame]
    set txt [text .textFrame.text -wrap word \
        -yscrollcommand {.textFrame.scrolly set} -font Mono]
    bindtags $txt {$txt Ntext . all}
    ttk::scrollbar .textFrame.scrolly -orient vertical \
        -command {.textFrame.text yview}
    pack .textFrame.scrolly -side right -fill y -expand true
    pack .textFrame.text -side left -fill both -expand true
    autoscroll::autoscroll .textFrame.scrolly
    list $textFrame $txt
}

proc gui_misc::open_webpage url {
    if {[tk windowingsystem] eq "win32"} {
        set cmd [list {*}[auto_execok start] {}]
    } else {
        set cmd [auto_execok xdg-open]
    }
    try {
        exec {*}$cmd $url &
    } trap CHILDSTATUS {err} {
        puts "failed to open $url: $err"
    }
}

proc gui_misc::get_ini_filename {} {
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
