# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require gui_misc
package require misc
package require store
package require ui

namespace eval gui_about_form {}

proc gui_about_form::show_modal user_version {
    make_widgets $user_version
    make_layout
    make_bindings
    form::prepare .about { gui_about_form::on_close }
    form::show_modal .about
}

proc gui_about_form::make_widgets user_version {
    tk::toplevel .about
    wm title .about "[tk appname] — About"
    wm resizable .about false false
    set height 16
    tk::text .about.text -width 50 -height $height -wrap word \
        -background "#F0F0F0" -spacing3 $::VGAP
    populate_about_text $user_version
    .about.text configure -state disabled
    ttk::button .about.close_button -text Close -compound left \
        -image [ui::icon close.svg $::ICON_SIZE] \
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
        ui::open_webpage $url
    }
}


proc gui_about_form::on_close {} { form::delete .about }


proc gui_about_form::populate_about_text user_version {
    set txt .about.text
    add_text_tags $txt
    set img [$txt image create end -align center \
             -image [ui::icon store.svg 64]]
    $txt tag add spaceabove $img
    $txt tag add center $img
    set cmd [list $txt insert end]
    {*}$cmd "\nStore $::VERSION\n" {center title}
    {*}$cmd "An easy-to-use and simple alternative\n" {center navy}
    {*}$cmd "to a version control system.\n" {center navy}
    set year [clock format [clock seconds] -format %Y]
    if {$year > 2025} { set year "2025-[string range $year end-1 end]" }
    set bits [expr {8 * $::tcl_platform(wordSize)}]
    set distro [exec lsb_release -ds]
    {*}$cmd "https://github.com/mark-summerfield/store\n" {center green url}
    {*}$cmd "Copyright © $year Mark Summerfield.\nAll Rights Reserved.\n" \
        {center green}
    {*}$cmd "License: GPLv3.\n" {center green}
    {*}$cmd "[string repeat " " 60]\n" {center hr}
    {*}$cmd "Tcl/Tk $::tcl_patchLevel (${bits}-bit)\n" center
    {*}$cmd "[misc::sqlite_version] (.str $user_version)\n" center
    if {$distro != ""} { {*}$cmd "$distro\n" center }
    {*}$cmd "$::tcl_platform(os) $::tcl_platform(osVersion)\
        ($::tcl_platform(machine))\n" center
}

proc gui_about_form::add_text_tags txt {
    set margin 12
    $txt configure -font TkTextFont
    set cmd [list $txt tag configure]
    {*}$cmd spaceabove -spacing1 [expr {$::VGAP * 2}]
    {*}$cmd margins -lmargin1 $margin -lmargin2 $margin -rmargin $margin
    {*}$cmd center -justify center
    {*}$cmd title -foreground navy -font H1
    {*}$cmd navy -foreground navy
    {*}$cmd green -foreground darkgreen
    {*}$cmd bold -font bold
    {*}$cmd italic -font italic
    {*}$cmd url -underline true -underlinefg darkgreen
    {*}$cmd hr -overstrike true -overstrikefg lightgray -spacing3 10
}
