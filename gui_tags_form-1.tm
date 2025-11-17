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
    my show_modal .tagsForm.mf.tagEntry
}

oo::define TagsForm method make_widgets {} {
    set form [ttk::frame .tagsForm.mf]
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
    ui::apply_edit_bindings $form.generationsCombobox
    ttk::label $form.tagLabel -text Tag: -underline 0
    ttk::style configure TagSaved.TEntry -fieldbackground white
    ttk::style configure TagUnsaved.TEntry -fieldbackground #FFDDE2
    ttk::style configure TagInvalid.TEntry -fieldbackground #FFDDE2 \
        -foreground red
    ttk::entry $form.tagEntry -textvariable [my varname Tag] \
        -style TagSaved.TEntry
    ui::apply_edit_bindings $form.tagEntry
    ttk::frame $form.mf
    ttk::button $form.mf.saveButton -text "Save Tag" -underline 0 \
        -compound left -image [ui::icon document-save.svg $::ICON_SIZE] \
        -command [callback on_save]
    ttk::button $form.mf.untagButton -text "Delete Tag" -underline 0 \
        -compound left -image [ui::icon edit-cut.svg $::ICON_SIZE] \
        -command [callback on_untag]
    ttk::button $form.mf.closeButton -text Close \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command [callback on_close]
}


oo::define TagsForm method make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    set form .tagsForm.mf
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
    grid $form.mf -row 3 -column 0 -columnspan 4
    grid $form.mf.saveButton -row 0 -column 0 {*}$opts
    grid $form.mf.untagButton -row 0 -column 1 {*}$opts
    grid $form.mf.closeButton -row 0 -column 2 {*}$opts
    pack $form -fill both -expand 1
}


oo::define TagsForm method make_bindings {} {
    bind .tagsForm.mf.generationsCombobox <<ComboboxSelected>> \
        [callback on_generation_changed]
    bind .tagsForm <Alt-a> { .tagsForm.mf.showAllRadio invoke }
    bind .tagsForm <Alt-d> [callback on_untag]
    bind .tagsForm <Alt-e> { .tagsForm.mf.showTaggedRadio invoke }
    bind .tagsForm <Alt-g> { focus .tagsForm.mf.generationsCombobox }
    bind .tagsForm <Alt-s> [callback on_save]
    bind .tagsForm <Alt-t> { focus .tagsForm.mf.tagEntry }
    bind .tagsForm <Alt-u> { .tagsForm.mf.showUntaggedRadio invoke }
    bind .tagsForm <Escape> [callback on_close]
}

oo::define TagsForm method populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set StoreFilename $store_filename
    }
    set str [Store new $StoreFilename]
    try {
        set gids [$str gids $ShowWhich]
        .tagsForm.mf.generationsCombobox configure -values $gids
        if {[llength $gids]} {
            .tagsForm.mf.generationsCombobox set [lindex $gids 0]
        }
        lassign [util::n_s [llength $gids]] n s
        .tagsForm.mf.generationsLabel configure \
            -text "Generation$s ($n):"
    } finally {
        $str destroy
    }
    my on_generation_changed
}

oo::define TagsForm method on_show_changed {} { my populate }

oo::define TagsForm method on_generation_changed {} {
    set gid [.tagsForm.mf.generationsCombobox get]
    set str [Store new $StoreFilename]
    try {
        set tag [$str tag $gid]
    } finally {
        $str destroy
    }
    .tagsForm.mf.tagEntry delete 0 end
    if {$tag ne ""} { .tagsForm.mf.tagEntry insert 0 $tag }
    set OldTag $tag
    my on_entry_changed
}

oo::define TagsForm method on_tag_changed args { my on_entry_changed }

oo::define TagsForm method on_entry_changed {} {
    if {$Tag ne ""} {
        .tagsForm.mf.mf.untagButton state !disabled
    } else {
        .tagsForm.mf.mf.untagButton state disabled
    }
    if {[string is integer -strict $Tag]} {
        .tagsForm.mf.tagEntry configure -style TagInvalid.TEntry
        .tagsForm.mf.mf.saveButton state disabled
    } elseif {$Tag eq $OldTag} {
        .tagsForm.mf.tagEntry configure -style TagSaved.TEntry
        .tagsForm.mf.mf.saveButton state disabled
    } else {
        set str [Store new $StoreFilename]
        try {
            if {[$str validtag $Tag]} {
                .tagsForm.mf.tagEntry configure -style TagUnsaved.TEntry
                .tagsForm.mf.mf.saveButton state !disabled
            } else {
                .tagsForm.mf.tagEntry configure -style TagInvalid.TEntry
                .tagsForm.mf.mf.saveButton state disabled
            }
        } finally {
            $str destroy
        }
    }
    return true
}

oo::define TagsForm method on_save {} {
    set gid [.tagsForm.mf.generationsCombobox get]
    set tag [.tagsForm.mf.tagEntry get]
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
    set gid [.tagsForm.mf.generationsCombobox get]
    .tagsForm.mf.tagEntry delete 0 end
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
