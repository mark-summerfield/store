# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require lambda 1
package require misc
package require store

namespace eval gui_tags {}

proc gui_tags::show_modal {store_filename refresh} {
    set ::gui_tags::Refresh $refresh
    if {![winfo exists .tagsForm]} {
        set ::gui_tags::ShowWhich all
        set ::gui_tags::OldTag ""
        set ::gui_tags::Tag ""
        trace add variable ::gui_tags::Tag write ::gui_tags::on_tag_changed 
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

proc gui_tags::make_widgets {} {
    ttk::label .tagsForm.showLabel -text "Show Generations"
    ttk::radiobutton .tagsForm.showAllRadio -text All -underline 0 \
        -value all -variable ::gui_tags::ShowWhich \
        -command ::gui_tags::on_show_changed
    ttk::radiobutton .tagsForm.showUntaggedRadio -text Untagged \
        -underline 0 -value untagged -variable ::gui_tags::ShowWhich \
        -command ::gui_tags::on_show_changed
    ttk::radiobutton .tagsForm.showTaggedRadio -text Tagged -underline 4 \
        -value tagged -variable ::gui_tags::ShowWhich \
        -command ::gui_tags::on_show_changed
    ttk::label .tagsForm.generationsLabel -text Generation: -underline 0
    ttk::label .tagsForm.atLabel -text @ 
    ttk::combobox .tagsForm.generationsCombobox
    ttk::label .tagsForm.tagLabel -text Tag: -underline 0
    ttk::style configure TagSaved.TEntry -fieldbackground white
    ttk::style configure TagUnsaved.TEntry -fieldbackground #FFDDE2
    ttk::style configure TagInvalid.TEntry -fieldbackground #FFDDE2 \
        -foreground red
    ttk::entry .tagsForm.tagEntry -textvariable ::gui_tags::Tag \
        -style TagSaved.TEntry
    ttk::frame .tagsForm.frame
    ttk::button .tagsForm.frame.saveButton -text Save -underline 0 \
        -compound left -image [form::icon document-save.svg $::ICON_SIZE] \
        -command gui_tags::on_save
    ttk::button .tagsForm.frame.closeButton -text Close \
        -compound left -image [form::icon close.svg $::ICON_SIZE] \
        -command gui_tags::on_close
}


proc gui_tags::make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .tagsForm.showLabel -row 0 -column 0 -sticky w {*}$opts
    grid .tagsForm.showAllRadio -row 0 -column 1 -sticky w {*}$opts
    grid .tagsForm.showUntaggedRadio -row 0 -column 2 -sticky w {*}$opts
    grid .tagsForm.showTaggedRadio -row 0 -column 3 -sticky w {*}$opts
    grid .tagsForm.generationsLabel -row 1 -column 0 -sticky w {*}$opts
    grid .tagsForm.atLabel -row 1 -column 1 -sticky e {*}$opts
    grid .tagsForm.generationsCombobox -row 1 -column 2 -columnspan 3 \
        -sticky we {*}$opts
    grid .tagsForm.tagLabel -row 2 -column 0 -columnspan 2 -sticky w \
        {*}$opts
    grid .tagsForm.tagEntry -row 2 -column 2 -columnspan 3 -sticky we \
        {*}$opts
    grid .tagsForm.frame -row 3 -column 0 -columnspan 4
    grid .tagsForm.frame.saveButton -row 0 -column 0 {*}$opts
    grid .tagsForm.frame.closeButton -row 0 -column 1 {*}$opts
}


proc gui_tags::make_bindings {} {
    bind .tagsForm.generationsCombobox <<ComboboxSelected>> {
        gui_tags::on_generation_changed
    }
    bind .tagsForm <Alt-a> { .tagsForm.showAllRadio invoke }
    bind .tagsForm <Alt-e> { .tagsForm.showTaggedRadio invoke }
    bind .tagsForm <Alt-g> { focus .tagsForm.generationsCombobox }
    bind .tagsForm <Alt-s> { gui_tags::on_save }
    bind .tagsForm <Alt-t> { focus .tagsForm.tagEntry }
    bind .tagsForm <Alt-u> { .tagsForm.showUntaggedRadio invoke }
    bind .tagsForm <Escape> { gui_tags::on_close }
}

proc gui_tags::populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set ::gui_tags::StoreFilename $store_filename
    }
    if {[winfo exists .tagsForm]} {
        set str [Store new $::gui_tags::StoreFilename]
        try {
            set gids [$str gids $::gui_tags::ShowWhich]
            .tagsForm.generationsCombobox configure -values $gids
            if {[llength $gids]} {
                .tagsForm.generationsCombobox set [lindex $gids 0]
            }
            lassign [misc::n_s [llength $gids]] n s
            .tagsForm.generationsLabel configure -text "Generation$s ($n):"
        } finally {
            $str destroy
        }
        on_generation_changed
    }
}

proc gui_tags::on_show_changed {} {
    if {[winfo exists .tagsForm]} { populate }
}

proc gui_tags::on_generation_changed {} {
    if {[winfo exists .tagsForm]} {
        set gid [.tagsForm.generationsCombobox get]
        set str [Store new $::gui_tags::StoreFilename]
        try {
            set tag [$str tag $gid]
        } finally {
            $str destroy
        }
        .tagsForm.tagEntry delete 0 end
        if {$tag ne ""} { .tagsForm.tagEntry insert 0 $tag }
        set ::gui_tags::OldTag $tag
        on_entry_changed
    }
}

proc gui_tags::on_tag_changed args {
    ::gui_tags::on_entry_changed
}

proc gui_tags::on_entry_changed {} {
    if {[string is integer -strict $::gui_tags::Tag]} {
        .tagsForm.tagEntry configure -style TagInvalid.TEntry
        .tagsForm.frame.saveButton state disabled
    } elseif {$::gui_tags::Tag eq $::gui_tags::OldTag} {
        .tagsForm.tagEntry configure -style TagSaved.TEntry
        .tagsForm.frame.saveButton state disabled
    } else {
        .tagsForm.tagEntry configure -style TagUnsaved.TEntry
        .tagsForm.frame.saveButton state !disabled
    }
    return true
}

proc gui_tags::on_save {} {
    if {[winfo exists .tagsForm]} {
        set gid [.tagsForm.generationsCombobox get]
        set tag [.tagsForm.tagEntry get]
        set str [Store new $::gui_tags::StoreFilename]
        try {
            $str tag $gid [expr {$tag eq "" ? "-" : $tag}]
        } finally {
            $str destroy
        }
        set ::gui_tags::OldTag $tag
        on_entry_changed
    }
}

proc gui_tags::on_close {} {
    form::hide .tagsForm
    {*}$::gui_tags::Refresh
}
