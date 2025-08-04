# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require gui_misc
package require misc
package require store

namespace eval gui_about_form {}

proc gui_about_form::show_modal {} {
    make_widgets
    make_layout
    make_bindings
    form::prepare .about { gui_about_form::on_close }
    form::show_modal .about
}

proc gui_about_form::make_widgets {} {
    tk::toplevel .about
    wm title .about "[tk appname] — About"
    wm resizable .about false false
    set height 16
    tk::text .about.text -width 50 -height $height -wrap word \
        -background "#F0F0F0" -spacing3 $::VGAP
    populate_about_text
    .about.text configure -state disabled
    ttk::button .about.close_button -text Close -compound left \
        -image [form::icon close.svg $::ICON_SIZE] \
        -command { gui_about_form::on_close }
}


proc gui_about_form::make_layout {} {
    grid .about.text -sticky nsew -pady $::PAD
    grid .about.close_button -pady $::PAD
}


proc gui_about_form::make_bindings {} {
    bind .about <Escape> { gui_about_form::on_close }
    bind .about <Return> { gui_about_form::on_close }
    .about.text tag bind url <Double-1> {
        gui_about_form::on_click_url @%x,%y
    }
}


proc gui_about_form::on_click_url index {
    set indexes [.about.text tag prevrange url $index]
    set url [string trim [.about.text get {*}$indexes]]
    if {$url ne ""} {
        if {![string match -nocase http*://* $url]} {
            set url [string cat http:// $url]
        }
        gui_misc::open_webpage $url
    }
}


proc gui_about_form::on_close {} { form::delete .about }


proc gui_about_form::populate_about_text {} {
    add_text_tags .about.text
    set img [.about.text image create end -align center \
             -image [form::icon store.svg 64]]
    .about.text tag add spaceabove $img
    .about.text tag add center $img
    .about.text insert end "\nStore $::VERSION\n" {center title}
    .about.text insert end "An easy-to-use and simple alternative\n" \
            {center navy}
    .about.text insert end "to a version control system.\n" {center navy}
    set year [clock format [clock seconds] -format %Y]
    if {$year > 2025} {
        set year "2025-[string range $year end-1 end]"
    }
    set bits [expr {8 * $::tcl_platform(wordSize)}]
    set distro [exec lsb_release -ds]
    .about.text insert end \
        "https://github.com/mark-summerfield/store\n" {center green url}
    .about.text insert end "Copyright © $year Mark Summerfield.\
                            \nAll Rights Reserved.\n" {center green}
    .about.text insert end "License: GPLv3.\n" {center green}
    .about.text insert end "[string repeat " " 60]\n" {center hr}
    .about.text insert end "Tcl/Tk $::tcl_patchLevel (${bits}-bit)\n" center
    .about.text insert end "[misc::sqlite_version]\n" center
    if {$distro != ""} { .about.text insert end "$distro\n" center }
    .about.text insert end "$::tcl_platform(os) $::tcl_platform(osVersion)\
        ($::tcl_platform(machine))\n" center
}

proc gui_about_form::add_text_tags txt {
    set margin 12
    $txt configure -font TkTextFont
    $txt tag configure spaceabove -spacing1 [expr {$::VGAP * 2}]
    $txt tag configure margins -lmargin1 $margin -lmargin2 $margin \
        -rmargin $margin
    $txt tag configure center -justify center
    $txt tag configure title -foreground navy -font h1
    $txt tag configure navy -foreground navy
    $txt tag configure green -foreground darkgreen
    $txt tag configure bold -font bold
    $txt tag configure italic -font italic
    $txt tag configure url -underline true -underlinefg darkgreen
    $txt tag configure hr -overstrike true -overstrikefg lightgray \
        -spacing3 10
}
