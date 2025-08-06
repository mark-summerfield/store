# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval form {}

proc form::prepare {window on_close {modal true} {x 0} {y 0}} {
    wm withdraw $window
    wm attributes $window -type dialog
    if {$modal} {
        wm transient $window .
    }
    wm group $window .
    set parent [winfo parent $window]
    if {!($x && $y)} {
        set x [expr {[winfo x $parent] + [winfo width $parent] / 3}]
        set y [expr {[winfo y $parent] + [winfo height $parent] / 3}]
    }
    wm geometry $window "+$x+$y"
    wm protocol $window WM_DELETE_WINDOW $on_close
}

proc form::show_modal {form {focus_widget ""}} {
    wm deiconify $form
    grab set $form
    raise $form
    update
    focus $form
    if {$focus_widget ne ""} { focus $focus_widget }
}

proc form::show_modeless form {
    wm deiconify $form
    raise $form
    update
    focus $form
}

proc form::delete form {
    grab release $form
    destroy $form
}

proc form::hide form {
    grab release $form
    wm withdraw $form
}
