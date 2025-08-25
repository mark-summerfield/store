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
    tkwait window [$form form]
    $yesno get
}

oo::define YesNoForm constructor {yesno title body_text default} {
    set YesNo $yesno
    my make_widgets $title $body_text
    my make_layout
    my make_bindings $default
    next .yesnoForm [callback on_no]
    my show_modal [expr {$default eq "yes" ? {.yesnoForm.yes_button} \
                                           : {.yesnoForm.no_button}}]
}

oo::define YesNoForm method form {} { return .yesnoForm }

oo::define YesNoForm method make_widgets {title body_text} {
    if {[info exists ::ICON_SIZE]} {
        set size $::ICON_SIZE
    } else {
        set size [expr {max(24, round(16 * [tk scaling]))}]
    }
    tk::toplevel .yesnoForm
    wm resizable .yesnoForm false false
    wm title .yesnoForm $title
    ttk::label .yesnoForm.label -text $body_text -anchor center \
        -compound left -padding $::PAD \
        -image [ui::icon help.svg [expr {2 * $::ICON_SIZE}]]
    ttk::button .yesnoForm.yes_button -text Yes -underline 0 \
        -command [callback on_yes] -compound left \
        -image [ui::icon yes.svg $size]
    ttk::button .yesnoForm.no_button -text No -underline 0 \
        -command [callback on_no] -compound left \
        -image [ui::icon no.svg $size]
}


oo::define YesNoForm method make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .yesnoForm.label -row 0 -column 0 -columnspan 2 -sticky news \
        {*}$opts
    grid .yesnoForm.yes_button -row 1 -column 0 -sticky e {*}$opts
    grid .yesnoForm.no_button -row 1 -column 1 -sticky w {*}$opts
    grid rowconfigure .yesnoForm 0 -weight 1
    grid columnconfigure .yesnoForm 0 -weight 1
    grid columnconfigure .yesnoForm 1 -weight 1
}

oo::define YesNoForm method make_bindings default {
    bind .yesnoForm <Escape> [callback on_no]
    if {$default eq "yes"} {
        bind .yesnoForm <Return> [callback on_yes]
    } else {
        bind .yesnoForm <Return> [callback on_no]
    }
    bind .yesnoForm <n> [callback on_no]
    bind .yesnoForm <Alt-n> [callback on_no]
    bind .yesnoForm <y> [callback on_yes]
    bind .yesnoForm <Alt-y> [callback on_yes]
}

oo::define YesNoForm method on_yes {} {
    $YesNo set yes
    my delete
}

oo::define YesNoForm method on_no {} {
    $YesNo set no
    my delete
}
