# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require lambda 1
package require store
package require ui

namespace eval gui_tags_form {}

proc gui_tags_form::show_modal {store_filename refresh} {
    set ::gui_tags_form::Refresh $refresh
    if {![winfo exists .tagsForm]} {
        set ::gui_tags_form::ShowWhich all
        set ::gui_tags_form::OldTag ""
        set ::gui_tags_form::Tag ""
        trace add variable ::gui_tags_form::Tag write \
            ::gui_tags_form::on_tag_changed 
        toplevel .tagsForm
        wm title .tagsForm "[tk appname] — Tags"
        make_widgets
        make_layout
        make_bindings
        wm resizable .tagsForm false false
        set on_close [lambda {} {form::hide .tagsForm}]
        form::prepare .tagsForm $on_close false
        populate $store_filename
    }
    form::show_modal .tagsForm .tagsForm.tagEntry
}

proc gui_tags_form::make_widgets {} {
    set form .tagsForm
    ttk::label $form.showLabel -text "Show Generations"
    ttk::radiobutton $form.showAllRadio -text All -underline 0 \
        -value all -variable ::gui_tags_form::ShowWhich \
        -command ::gui_tags_form::on_show_changed
    ttk::radiobutton $form.showUntaggedRadio -text Untagged \
        -underline 0 -value untagged -variable ::gui_tags_form::ShowWhich \
        -command ::gui_tags_form::on_show_changed
    ttk::radiobutton $form.showTaggedRadio -text Tagged -underline 4 \
        -value tagged -variable ::gui_tags_form::ShowWhich \
        -command ::gui_tags_form::on_show_changed
    ttk::label $form.generationsLabel -text Generation: -underline 0
    ttk::label $form.atLabel -text @ 
    ttk::combobox $form.generationsCombobox
    ttk::label $form.tagLabel -text Tag: -underline 0
    ttk::style configure TagSaved.TEntry -fieldbackground white
    ttk::style configure TagUnsaved.TEntry -fieldbackground #FFDDE2
    ttk::style configure TagInvalid.TEntry -fieldbackground #FFDDE2 \
        -foreground red
    ttk::entry $form.tagEntry -textvariable ::gui_tags_form::Tag \
        -style TagSaved.TEntry
    ttk::frame $form.frame
    ttk::button $form.frame.saveButton -text Save -underline 0 \
        -compound left -image [ui::icon document-save.svg $::ICON_SIZE] \
        -command gui_tags_form::on_save
    ttk::button $form.frame.closeButton -text Close \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command gui_tags_form::on_close
}


proc gui_tags_form::make_layout {} {
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
    grid $form.frame.closeButton -row 0 -column 1 {*}$opts
}


proc gui_tags_form::make_bindings {} {
    bind .tagsForm.generationsCombobox <<ComboboxSelected>> {
        gui_tags_form::on_generation_changed
    }
    bind .tagsForm <Alt-a> { .tagsForm.showAllRadio invoke }
    bind .tagsForm <Alt-e> { .tagsForm.showTaggedRadio invoke }
    bind .tagsForm <Alt-g> { focus .tagsForm.generationsCombobox }
    bind .tagsForm <Alt-s> { gui_tags_form::on_save }
    bind .tagsForm <Alt-t> { focus .tagsForm.tagEntry }
    bind .tagsForm <Alt-u> { .tagsForm.showUntaggedRadio invoke }
    bind .tagsForm <Escape> { gui_tags_form::on_close }
}

proc gui_tags_form::populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set ::gui_tags_form::StoreFilename $store_filename
    }
    if {[winfo exists .tagsForm]} {
        set str [Store new $::gui_tags_form::StoreFilename]
        try {
            set gids [$str gids $::gui_tags_form::ShowWhich]
            .tagsForm.generationsCombobox configure -values $gids
            if {[llength $gids]} {
                .tagsForm.generationsCombobox set [lindex $gids 0]
            }
            lassign [ui::n_s [llength $gids]] n s
            .tagsForm.generationsLabel configure -text "Generation$s ($n):"
        } finally {
            $str destroy
        }
        on_generation_changed
    }
}

proc gui_tags_form::on_show_changed {} {
    if {[winfo exists .tagsForm]} { populate }
}

proc gui_tags_form::on_generation_changed {} {
    if {[winfo exists .tagsForm]} {
        set gid [.tagsForm.generationsCombobox get]
        set str [Store new $::gui_tags_form::StoreFilename]
        try {
            set tag [$str tag $gid]
        } finally {
            $str destroy
        }
        .tagsForm.tagEntry delete 0 end
        if {$tag ne ""} { .tagsForm.tagEntry insert 0 $tag }
        set ::gui_tags_form::OldTag $tag
        on_entry_changed
    }
}

proc gui_tags_form::on_tag_changed args {
    ::gui_tags_form::on_entry_changed
}

proc gui_tags_form::on_entry_changed {} {
    if {[string is integer -strict $::gui_tags_form::Tag]} {
        .tagsForm.tagEntry configure -style TagInvalid.TEntry
        .tagsForm.frame.saveButton state disabled
    } elseif {$::gui_tags_form::Tag eq $::gui_tags_form::OldTag} {
        .tagsForm.tagEntry configure -style TagSaved.TEntry
        .tagsForm.frame.saveButton state disabled
    } else {
        .tagsForm.tagEntry configure -style TagUnsaved.TEntry
        .tagsForm.frame.saveButton state !disabled
    }
    return true
}

proc gui_tags_form::on_save {} {
    if {[winfo exists .tagsForm]} {
        set gid [.tagsForm.generationsCombobox get]
        set tag [.tagsForm.tagEntry get]
        set str [Store new $::gui_tags_form::StoreFilename]
        try {
            $str tag $gid [expr {$tag eq "" ? "-" : $tag}]
        } finally {
            $str destroy
        }
        set ::gui_tags_form::OldTag $tag
        on_entry_changed
    }
}

proc gui_tags_form::on_close {} {
    form::hide .tagsForm
    {*}$::gui_tags_form::Refresh
}
