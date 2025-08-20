# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require ref
package require ui

oo::class create YesNoForm {
    variable YesNo
}

oo::define YesNoForm classmethod show_modal {title body_text \
        {default yes}} {
    set yesno [Ref new $default]
    set form [YesNoForm new $yesno $title $body_text $default]
    tkwait window .yesno
    $yesno get
}

oo::define YesNoForm constructor {yesno title body_text default} {
    set YesNo $yesno
    my make_widgets $title $body_text
    my make_layout
    my make_bindings $default
    form::prepare .yesno [callback on_no]
    form::show_modal .yesno [expr {$default eq "yes" ? {.yesno.yes_button} \
                                                     : {.yesno.no_button}}]
}

oo::define YesNoForm method make_widgets {title body_text} {
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
        -command [callback on_yes] -compound left \
        -image [ui::icon yes.svg $size]
    ttk::button .yesno.no_button -text No -underline 0 \
        -command [callback on_no] -compound left \
        -image [ui::icon no.svg $size]
}


oo::define YesNoForm method make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .yesno.label -row 0 -column 0 -columnspan 2 -sticky news {*}$opts
    grid .yesno.yes_button -row 1 -column 0 -sticky e {*}$opts
    grid .yesno.no_button -row 1 -column 1 -sticky w {*}$opts
    grid rowconfigure .yesno 0 -weight 1
    grid columnconfigure .yesno 0 -weight 1
    grid columnconfigure .yesno 1 -weight 1
}

oo::define YesNoForm method make_bindings default {
    bind .yesno <Escape> [callback on_no]
    if {$default eq "yes"} {
        bind .yesno <Return> [callback on_yes]
    } else {
        bind .yesno <Return> [callback on_no]
    }
    bind .yesno <n> [callback on_no]
    bind .yesno <Alt-n> [callback on_no]
    bind .yesno <y> [callback on_yes]
    bind .yesno <Alt-y> [callback on_yes]
}

oo::define YesNoForm method on_yes {} {
    $YesNo set yes
    form::delete .yesno
}

oo::define YesNoForm method on_no {} {
    $YesNo set no
    form::delete .yesno
}
