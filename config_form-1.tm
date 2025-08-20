# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require tooltip 2
package require ui

oo::class create ConfigForm {
    superclass AbstractForm

    variable Cfg
    variable Blinking
    variable FontFamily
    variable FontSize
    variable Ok
}

oo::define ConfigForm constructor {ok cfg} {
    set Ok $ok
    set Cfg $cfg
    set Blinking [$Cfg blinking]
    set FontFamily [$Cfg fontfamily]
    set FontSize [$Cfg fontsize]
    my make_widgets 
    my make_layout
    my make_bindings
    next .config [callback on_cancel]
    my show_modal .config.scaleSpinbox
}

oo::define ConfigForm method make_widgets {} {
    tk::toplevel .config
    wm minsize .config 320 180
    wm title .config "[tk appname] — Config"
    set tip tooltip::tooltip
    ttk::label .config.scaleLabel -text "Application Scale" -underline 12
    ttk::spinbox .config.scaleSpinbox -format %.2f -from 1.0 -to 10.0 \
        -increment 0.1
    $tip .config.scaleSpinbox "Application’s scale factor (only applied\
        after restart)"
    .config.scaleSpinbox set [format %.2f [tk scaling]]
    ttk::checkbutton .config.blinkCheckbutton -text "Cursor Blink" \
        -underline 7 -variable [my varname Blinking]
    if {$Blinking} { .config.blinkCheckbutton state selected }
    $tip .config.blinkCheckbutton "Whether the text cursor should blink."
    ttk::button .config.fontButton -text Font… -underline 0 -compound left \
        -image [ui::icon preferences-desktop-font.svg $::ICON_SIZE] \
        -command [callback on_font]
    $tip .config.fontButton "The font to use for displaying man pages."
    ttk::label .config.fontLabel -relief sunken \
        -text "[$Cfg fontfamily] [$Cfg fontsize]"
    ttk::label .config.configFileLabel -text "Config file"
    ttk::label .config.configFilenameLabel  \
        -foreground gray25 -text [$Cfg filename]
    ttk::frame .config.buttons
    ttk::button .config.buttons.okButton -text OK -underline 0 \
        -compound left -image [ui::icon ok.svg $::ICON_SIZE] \
        -command [callback on_ok]
    ttk::button .config.buttons.cancelButton -text Cancel -compound left \
        -image [ui::icon gtk-cancel.svg $::ICON_SIZE] \
        -command [callback on_cancel]
}


oo::define ConfigForm method make_layout {} {
    const opts "-padx 3 -pady 3"
    grid .config.scaleLabel -row 0 -column 0 -sticky w {*}$opts
    grid .config.scaleSpinbox -row 0 -column 1 -columnspan 2 -sticky we \
        {*}$opts
    grid .config.fontButton -row 1 -column 0 -sticky w {*}$opts
    grid .config.fontLabel -row 1 -column 1 -columnspan 2 -sticky news \
        {*}$opts
    grid .config.blinkCheckbutton -row 2 -column 1 -sticky we
    grid .config.configFileLabel -row 8 -column 0 -sticky we {*}$opts
    grid .config.configFilenameLabel -row 8 -column 1 -columnspan 2 \
        -sticky we {*}$opts
    grid .config.buttons -row 9 -column 0 -columnspan 3 -sticky we
    pack [ttk::frame .config.buttons.pad1] -side left -expand true
    pack .config.buttons.okButton -side left {*}$opts
    pack .config.buttons.cancelButton -side left {*}$opts
    pack [ttk::frame .config.buttons.pad2] -side right -expand true
    grid columnconfigure .config 1 -weight 1
}


oo::define ConfigForm method make_bindings {} {
    bind .config <Escape> [callback on_cancel]
    bind .config <Return> [callback on_ok]
    bind .config <Alt-b> {.config.blinkCheckbutton invoke}
    bind .config <Alt-f> [callback on_font]
    bind .config <Alt-o> [callback on_ok]
    bind .config <Alt-s> {focus .config.scaleSpinbox}
}


oo::define ConfigForm method on_font {} {
    tk fontchooser configure -parent .config \
        -title "[tk appname] — Choose Font" -font Mono \
        -command [callback on_font_chosen]
    tk fontchooser show
}

oo::define ConfigForm method on_font_chosen args {
    if {[llength $args] > 0} {
        set args [lindex $args 0]
        if {[llength $args] > 1} {
            set FontFamily [lindex $args 0]
            set FontSize [lindex $args 1]
            .config.fontLabel configure -text "$FontFamily $FontSize"
        }
    }
}

oo::define ConfigForm method on_ok {} {
    tk scaling [.config.scaleSpinbox get]
    $Cfg set_blinking $Blinking
    $Cfg set_fontfamily $FontFamily
    $Cfg set_fontsize $FontSize
    $Ok set true
    my delete
}

oo::define ConfigForm method on_cancel {} { my delete }
