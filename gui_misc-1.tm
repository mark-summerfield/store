# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ntext 1

namespace eval gui_misc {}

proc gui_misc::make_text_frame {} {
    set textFrame [ttk::frame .textFrame]
    set txt [text .textFrame.text -wrap word \
        -yscrollcommand {.textFrame.scrolly set} -font Mono]
    bindtags $txt {$txt Ntext . all}
    $txt tag configure sel -selectbackground yellow
    ttk::scrollbar .textFrame.scrolly -orient vertical \
        -command {.textFrame.text yview}
    pack .textFrame.scrolly -side right -fill y -expand true
    pack .textFrame.text -side left -fill both -expand true
    autoscroll::autoscroll .textFrame.scrolly
    list $textFrame $txt
}

proc gui_misc::set_tree_tags tree {
    $tree tag configure parent -foreground blue
    $tree tag configure untracked -foreground gray
    $tree tag configure generation -foreground green
    $tree tag configure updatable -foreground red
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
