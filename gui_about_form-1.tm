# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require db
package require ui

oo::class create AboutForm {
    superclass AbstractForm
}

oo::define AboutForm constructor user_version {
    my make_widgets $user_version
    my make_layout
    my make_bindings
    next .about [callback on_close]
    my show_modal .about.closeBUtton
}

oo::define AboutForm method make_widgets user_version {
    tk::toplevel .about
    wm title .about "[tk appname] — About"
    wm resizable .about false false
    set height 16
    tk::text .about.text -width 50 -height $height -wrap word \
        -background "#F0F0F0" -spacing3 $::VGAP
    my populate $user_version
    .about.text configure -state disabled
    ttk::button .about.closeBUtton -text Close -compound left \
        -image [ui::icon close.svg $::ICON_SIZE] \
        -command [callback on_close]
}

oo::define AboutForm method make_layout {} {
    grid .about.text -sticky nsew -pady $::PAD
    grid .about.closeBUtton -pady $::PAD
}

oo::define AboutForm method make_bindings {} {
    bind .about <Escape> [callback on_close]
    bind .about <Return> [callback on_close]
    .about.text tag bind url <Double-1> [callback on_click_url @%x,%y]
}

oo::define AboutForm method on_click_url index {
    set indexes [.about.text tag prevrange url $index]
    set url [string trim [.about.text get {*}$indexes]]
    if {$url ne ""} {
        if {![string match -nocase http*://* $url]} {
            set url [string cat http:// $url]
        }
        ui::open_webpage $url
    }
}

oo::define AboutForm method on_close {} { my delete }

oo::define AboutForm method populate user_version {
    set txt .about.text
    my add_text_tags $txt
    set img [$txt image create end -align center \
             -image [ui::icon store.svg 64]]
    $txt tag add spaceabove $img
    $txt tag add center $img
    set add [list $txt insert end]
    {*}$add "\nStore $::VERSION\n" {center title}
    {*}$add "An easy-to-use and simple alternative\n" {center navy}
    {*}$add "to a version control system.\n" {center navy}
    set year [clock format [clock seconds] -format %Y]
    if {$year > 2025} { set year "2025-[string range $year end-1 end]" }
    set bits [expr {8 * $::tcl_platform(wordSize)}]
    set distro [exec lsb_release -ds]
    {*}$add "https://github.com/mark-summerfield/store\n" {center green url}
    {*}$add "Copyright © $year Mark Summerfield.\nAll Rights Reserved.\n" \
        {center green}
    {*}$add "License: GPLv3.\n" {center green}
    {*}$add "[string repeat " " 60]\n" {center hr}
    {*}$add "Tcl/Tk $::tcl_patchLevel (${bits}-bit)\n" center
    {*}$add "[db::sqlite_version] (.str $user_version)\n" center
    if {$distro != ""} { {*}$add "$distro\n" center }
    {*}$add "$::tcl_platform(os) $::tcl_platform(osVersion)\
        ($::tcl_platform(machine))\n" center
}

oo::define AboutForm method add_text_tags txt {
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
