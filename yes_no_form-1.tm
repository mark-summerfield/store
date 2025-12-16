# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require ref
package require ui

oo::class create YesNoForm {
    superclass AbstractForm

    variable YesNo
}

oo::define YesNoForm classmethod show {title body_text {default yes}} {
    set yesno [Ref new $default]
    set form [YesNoForm new $yesno $title $body_text $default]
    tkwait window .yesno_form
    $yesno get
}

oo::define YesNoForm constructor {yesno title body_text \
        default} {
    set YesNo $yesno
    my make_widgets $title $body_text
    my make_layout
    my make_bindings $default
    next .yesno_form [callback on_no]
    my show_modal [expr {$default eq "yes" \
        ? {.yesno_form.frame.yes_button} \
        : {.yesno_form.frame.no_button}}]
}

oo::define YesNoForm method make_widgets {title body_text} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .yesno_form
    wm resizable .yesno_form 0 0
    wm title .yesno_form $title
    ttk::frame .yesno_form.frame
    ttk::label .yesno_form.frame.label -text $body_text \
        -anchor center -compound left -padding 3 \
        -image [ui::icon help.svg [expr {2 * $::ICON_SIZE}]]
    ttk::button .yesno_form.frame.yes_button -text Yes \
        -underline 0 -command [callback on_yes] -compound left \
        -image [ui::icon yes.svg $size]
    ttk::button .yesno_form.frame.no_button -text No \
        -underline 0 -command [callback on_no] -compound left \
        -image [ui::icon no.svg $size]
}

oo::define YesNoForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    grid .yesno_form.frame.label -row 0 -column 0 \
        -columnspan 2 -sticky news {*}$opts
    grid .yesno_form.frame.yes_button -row 1 -column 0 \
        -sticky e {*}$opts
    grid .yesno_form.frame.no_button -row 1 -column 1 \
        -sticky w {*}$opts
    grid rowconfigure .yesno_form 0 -weight 1
    grid columnconfigure .yesno_form 0 -weight 1
    grid columnconfigure .yesno_form 1 -weight 1
    pack .yesno_form.frame -fill both -expand 1
}

oo::define YesNoForm method make_bindings default {
    bind .yesno_form <Escape> [callback on_no]
    if {$default eq "yes"} {
        bind .yesno_form <Return> [callback on_yes]
    } else {
        bind .yesno_form <Return> [callback on_no]
    }
    bind .yesno_form <n> [callback on_no]
    bind .yesno_form <Alt-n> [callback on_no]
    bind .yesno_form <y> [callback on_yes]
    bind .yesno_form <Alt-y> [callback on_yes]
}

oo::define YesNoForm method on_yes {} {
    $YesNo set yes
    my delete
}

oo::define YesNoForm method on_no {} {
    $YesNo set no
    my delete
}
