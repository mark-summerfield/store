# Copyright © 2025 Mark Summerfield. All rights reserved.

# TODO delete form namespace etc.

oo::abstract create AbstractForm {
    variable Window
}

oo::define AbstractForm constructor {window on_close {modal true} \
        {x 0} {y 0}} {
    set Window $window
    wm withdraw $Window
    wm attributes $Window -type dialog
    if {$modal} {
        wm transient $Window .
    }
    wm group $Window .
    set parent [winfo parent $Window]
    if {!($x && $y)} {
        set x [expr {[winfo x $parent] + [winfo width $parent] / 3}]
        set y [expr {[winfo y $parent] + [winfo height $parent] / 3}]
    }
    wm geometry $Window "+$x+$y"
    wm protocol $Window WM_DELETE_WINDOW $on_close
}

oo::define AbstractForm method show_modal {{focus_widget ""}} {
    wm deiconify $Window
    grab set $Window
    raise $Window
    update
    focus $Window
    if {$focus_widget ne ""} { focus $focus_widget }
}

oo::define AbstractForm method show_modeless {} {
    wm deiconify $Window
    raise $Window
    update
    focus $Window
}

oo::define AbstractForm method delete {} {
    grab release $Window
    destroy $Window
}

oo::define AbstractForm method hide {} {
    grab release $Window
    wm withdraw $Window
}
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
