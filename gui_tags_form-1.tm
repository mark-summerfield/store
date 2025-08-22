# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require lambda 1
package require store
package require ui
package require util

oo::singleton create TagsForm {
    superclass AbstractForm

    variable Refresh
    variable StoreFilename
    variable ShowWhich
    variable Tag
    variable OldTag
}

oo::define TagsForm constructor {} {
    set ShowWhich all
    set OldTag ""
    set Tag ""
    trace add variable [my varname Tag] write [callback on_tag_changed]
    toplevel .tagsForm
    wm title .tagsForm "[tk appname] — Tags"
    my make_widgets
    my make_layout
    my make_bindings
    wm resizable .tagsForm false false
    next .tagsForm [callback on_close]
}

oo::define TagsForm method show {store_filename refresh} {
    set StoreFilename $store_filename
    set Refresh $refresh
    my populate $StoreFilename
    my show_modal .tagsForm.tagEntry
}

oo::define TagsForm method make_widgets {} {
    set form .tagsForm
    ttk::label $form.showLabel -text "Show Generations"
    ttk::radiobutton $form.showAllRadio -text All -underline 0 \
        -value all -variable [my varname ShowWhich] \
        -command [callback on_show_changed]
    ttk::radiobutton $form.showUntaggedRadio -text Untagged \
        -underline 0 -value untagged -variable [my varname ShowWhich] \
        -command [callback on_show_changed]
    ttk::radiobutton $form.showTaggedRadio -text Tagged -underline 4 \
        -value tagged -variable [my varname ShowWhich] \
        -command [callback on_show_changed]
    ttk::label $form.generationsLabel -text Generation: -underline 0
    ttk::label $form.atLabel -text @ 
    ttk::combobox $form.generationsCombobox
    ttk::label $form.tagLabel -text Tag: -underline 0
    ttk::style configure TagSaved.TEntry -fieldbackground white
    ttk::style configure TagUnsaved.TEntry -fieldbackground #FFDDE2
    ttk::style configure TagInvalid.TEntry -fieldbackground #FFDDE2 \
        -foreground red
    ttk::entry $form.tagEntry -textvariable [my varname Tag] \
        -style TagSaved.TEntry
    ttk::frame $form.frame
    ttk::button $form.frame.saveButton -text "Save Tag" -underline 0 \
        -compound left -image [ui::icon document-save.svg $::ICON_SIZE] \
        -command [callback on_save]
    ttk::button $form.frame.untagButton -text "Delete Tag" -underline 0 \
        -compound left -image [ui::icon edit-cut.svg $::ICON_SIZE] \
        -command [callback on_untag]
    ttk::button $form.frame.closeButton -text Close \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command [callback on_close]
}


oo::define TagsForm method make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    set form .tagsForm
    grid $form.showLabel -row 0 -column 0 -sticky w {*}$opts
    grid $form.showAllRadio -row 0 -column 1 -sticky w {*}$opts
    grid $form.showUntaggedRadio -row 0 -column 2 -sticky w {*}$opts
    grid $form.showTaggedRadio -row 0 -column 3 -sticky w {*}$opts
    grid $form.generationsLabel -row 1 -column 0 -sticky w {*}$opts
    grid $form.atLabel -row 1 -column 1 -sticky e {*}$opts
    grid $form.generationsCombobox -row 1 -column 2 -columnspan 3 \
        -sticky we {*}$opts
    grid $form.tagLabel -row 2 -column 0 -columnspan 2 -sticky w {*}$opts
    grid $form.tagEntry -row 2 -column 2 -columnspan 3 -sticky we {*}$opts
    grid $form.frame -row 3 -column 0 -columnspan 4
    grid $form.frame.saveButton -row 0 -column 0 {*}$opts
    grid $form.frame.untagButton -row 0 -column 1 {*}$opts
    grid $form.frame.closeButton -row 0 -column 2 {*}$opts
}


oo::define TagsForm method make_bindings {} {
    bind .tagsForm.generationsCombobox <<ComboboxSelected>> \
        [callback on_generation_changed]
    bind .tagsForm <Alt-a> { .tagsForm.showAllRadio invoke }
    bind .tagsForm <Alt-d> [callback on_untag]
    bind .tagsForm <Alt-e> { .tagsForm.showTaggedRadio invoke }
    bind .tagsForm <Alt-g> { focus .tagsForm.generationsCombobox }
    bind .tagsForm <Alt-s> [callback on_save]
    bind .tagsForm <Alt-t> { focus .tagsForm.tagEntry }
    bind .tagsForm <Alt-u> { .tagsForm.showUntaggedRadio invoke }
    bind .tagsForm <Escape> [callback on_close]
}

oo::define TagsForm method populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set StoreFilename $store_filename
    }
    set str [Store new $StoreFilename]
    try {
        set gids [$str gids $ShowWhich]
        .tagsForm.generationsCombobox configure -values $gids
        if {[llength $gids]} {
            .tagsForm.generationsCombobox set [lindex $gids 0]
        }
        lassign [util::n_s [llength $gids]] n s
        .tagsForm.generationsLabel configure -text "Generation$s ($n):"
    } finally {
        $str destroy
    }
    my on_generation_changed
}

oo::define TagsForm method on_show_changed {} { my populate }

oo::define TagsForm method on_generation_changed {} {
    set gid [.tagsForm.generationsCombobox get]
    set str [Store new $StoreFilename]
    try {
        set tag [$str tag $gid]
    } finally {
        $str destroy
    }
    .tagsForm.tagEntry delete 0 end
    if {$tag ne ""} { .tagsForm.tagEntry insert 0 $tag }
    set OldTag $tag
    my on_entry_changed
}

oo::define TagsForm method on_tag_changed args { my on_entry_changed }

oo::define TagsForm method on_entry_changed {} {
    if {$Tag ne ""} {
        .tagsForm.frame.untagButton state !disabled
    } else {
        .tagsForm.frame.untagButton state disabled
    }
    if {[string is integer -strict $Tag]} {
        .tagsForm.tagEntry configure -style TagInvalid.TEntry
        .tagsForm.frame.saveButton state disabled
    } elseif {$Tag eq $OldTag} {
        .tagsForm.tagEntry configure -style TagSaved.TEntry
        .tagsForm.frame.saveButton state disabled
    } else {
        set str [Store new $StoreFilename]
        try {
            if {[$str validtag $Tag]} {
                .tagsForm.tagEntry configure -style TagUnsaved.TEntry
                .tagsForm.frame.saveButton state !disabled
            } else {
                .tagsForm.tagEntry configure -style TagInvalid.TEntry
                .tagsForm.frame.saveButton state disabled
            }
        } finally {
            $str destroy
        }
    }
    return true
}

oo::define TagsForm method on_save {} {
    set gid [.tagsForm.generationsCombobox get]
    set tag [.tagsForm.tagEntry get]
    set str [Store new $StoreFilename]
    try {
        $str tag $gid [expr {$tag eq "" ? "-" : $tag}]
    } finally {
        $str destroy
    }
    set OldTag $tag
    my on_entry_changed
}

oo::define TagsForm method on_untag {} {
    set gid [.tagsForm.generationsCombobox get]
    .tagsForm.tagEntry delete 0 end
    set str [Store new $StoreFilename]
    try {
        $str tag $gid -
    } finally {
        $str destroy
    }
    set OldTag ""
    my on_entry_changed
}

oo::define TagsForm method on_close {} {
    my hide
    {*}$Refresh
}
