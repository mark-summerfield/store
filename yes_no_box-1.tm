# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require ui

namespace eval yes_no_box {
    variable Reply
}

proc yes_no_box::show_modal {title body_text {default yes}} {
    make_widgets $title $body_text
    make_layout
    make_bindings $default
    form::prepare .yesno yes_no_box::on_no
    form::show_modal .yesno [expr {$default eq "yes" ? {.yesno.yes_button} \
                                                     : {.yesno.no_button}}]
    tkwait variable ::yes_no_box::Reply
    return $::yes_no_box::Reply
}

proc yes_no_box::make_widgets {title body_text} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .yesno
    wm resizable .yesno false false
    wm title .yesno $title
    ttk::label .yesno.label -text $body_text -anchor center -compound left \
        -padding $::PAD \
        -image [ui::icon help.svg [expr {2 * $::ICON_SIZE}]]
    ttk::button .yesno.yes_button -text Yes -underline 0 \
        -command { yes_no_box::on_yes } -compound left \
        -image [ui::icon yes.svg $size]
    ttk::button .yesno.no_button -text No -underline 0 \
        -command { yes_no_box::on_no } -compound left \
        -image [ui::icon no.svg $size]
}


proc yes_no_box::make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .yesno.label -row 0 -column 0 -columnspan 2 -sticky news {*}$opts
    grid .yesno.yes_button -row 1 -column 0 -sticky e {*}$opts
    grid .yesno.no_button -row 1 -column 1 -sticky w {*}$opts
    grid rowconfigure .yesno 0 -weight 1
    grid columnconfigure .yesno 0 -weight 1
    grid columnconfigure .yesno 1 -weight 1
}

proc yes_no_box::make_bindings default {
    bind .yesno <Escape> { yes_no_box::on_no }
    if {$default eq "yes"} {
        bind .yesno <Return> { yes_no_box::on_yes }
    } else {
        bind .yesno <Return> { yes_no_box::on_no }
    }
    bind .yesno <n> { yes_no_box::on_no }
    bind .yesno <Alt-n> { yes_no_box::on_no }
    bind .yesno <y> { yes_no_box::on_yes }
    bind .yesno <Alt-y> { yes_no_box::on_yes }
}

proc yes_no_box::on_yes {} {
    set ::yes_no_box::Reply yes
    form::delete .yesno
}

proc yes_no_box::on_no {} {
    set ::yes_no_box::Reply no
    form::delete .yesno
}
