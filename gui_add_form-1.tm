# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require lambda 1
package require store
package require ui

namespace eval gui_add_form {}

proc gui_add_form::show_modal {store_filename refresh names} {
    set ::gui_add_form::Refresh $refresh
    if {![winfo exists .addForm]} {
        toplevel .addForm
        wm title .addForm "[tk appname] — Add Addable"
        make_widgets
        make_layout
        make_bindings
        wm minsize .addForm 480 320
        set on_close [lambda {} {form::hide .addForm}]
        form::prepare .addForm $on_close false
    }
    populate $store_filename $names
    form::show_modal .addForm .addForm.addListFrame.addList
}

proc gui_add_form::make_widgets {} {
    set frame [ttk::frame .addForm.addListFrame]
    set name addList
    set addList [ttk::treeview $frame.$name -striped true]
    ui::scrollize $frame $name vertical
    ttk::style configure List.Treeview.Item -indicatorsize 0
    $addList configure -show tree -style List.Treeview
    $addList column #0 -anchor w -stretch true
    ttk::frame .addForm.controlsFrame
    ttk::button .addForm.controlsFrame.addButton -text Add \
        -compound left -image [ui::icon list-add.svg $::ICON_SIZE] \
        -command { gui_add_form::on_add } -underline 0
    ttk::label .addForm.controlsFrame.addLabel -text "All selected\
        files will be added;\nall unselected files will be ignored." \
        -wraplength 100p
    ttk::button .addForm.controlsFrame.closeButton -text Cancel \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command { gui_add_form::on_close }
}


proc gui_add_form::make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .addForm.addListFrame -row 0 -column 0 -sticky news
    grid .addForm.addListFrame.addList -row 0 -column 0 \
        -sticky news
    grid .addForm.addListFrame.scrolly -row 0 -column 1 -sticky ns
    grid columnconfigure .addForm.addListFrame 0 -weight 9
    grid rowconfigure .addForm.addListFrame 0 -weight 1
    autoscroll::autoscroll .addForm.addListFrame.scrolly
    grid .addForm.controlsFrame -row 0 -column 1 -sticky ns
    pack .addForm.controlsFrame.addButton -side top {*}$opts
    pack .addForm.controlsFrame.addLabel -side top -fill x {*}$opts
    pack .addForm.controlsFrame.closeButton -side bottom {*}$opts
    grid rowconfigure .addForm 0 -weight 1
    grid columnconfigure .addForm 0 -weight 1
}


proc gui_add_form::make_bindings {} {
    bind .addForm <Alt-a> { gui_add_form::on_add }
    bind .addForm <Escape> { gui_add_form::on_close }
}

proc gui_add_form::populate {{store_filename ""} {names ""}} {
    if {$store_filename ne ""} {
        set ::gui_add_form::StoreFilename $store_filename
    }
    if {[winfo exists .addForm]} {
        set addList .addForm.addListFrame.addList
        $addList delete [$addList children {}]
        if {![llength $names]} {
            set str [Store new $::gui_add_form::StoreFilename]
            try {
                set names [$str addable]
            } finally {
                $str destroy
            }
        }
        foreach name $names {
            set id [$addList insert {} end -text $name]
            $addList selection add $id
        }
    }
}

proc gui_add_form::on_add {} {
    if {[winfo exists .addForm]} {
        set addList .addForm.addListFrame.addList
        set seen [dict create]
        set addable [list]
        foreach id [$addList selection] {
            set name [$addList item $id -text]
            lappend addable $name
            dict set seen $name ""
        }
        set ignores [list]
        foreach id [$addList children {}] {
            set name [$addList item $id -text]
            if {![dict exists $seen $name]} {
                lappend ignores $name
            }
        }
        set str [Store new $::gui_add_form::StoreFilename]
        try {
            if {[llength $ignores]} { $str ignore {*}$ignores }
            if {[llength $addable]} { $str add {*}$addable }
        } finally {
            $str destroy
        }
        on_close
    }
}

proc gui_add_form::on_close {} {
    form::hide .addForm
    {*}$::gui_add_form::Refresh
}
