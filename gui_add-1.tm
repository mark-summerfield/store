# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require lambda 1
package require misc
package require store

namespace eval gui_add {}

proc gui_add::show_modal {store_filename refresh names} {
    set ::gui_add::Refresh $refresh
    if {![winfo exists .addForm]} {
        toplevel .addForm
        wm title .addForm "[tk appname] — Add Addable"
        make_widgets
        make_layout
        make_bindings
        wm minsize .addForm 480 320
        set on_close [lambda {} {form::hide .addForm}]
        form::prepare .addForm $on_close false
        populate $store_filename $names
    }
    form::show_modal .addForm .addForm.addListFrame.addList
}

proc gui_add::make_widgets {} {
    ttk::frame .addForm.addListFrame
    set addList [ttk::treeview \
        .addForm.addListFrame.addList -striped true \
        -yscrollcommand {.addForm.addListFrame.scrolly set}]
    ttk::style configure List.Treeview.Item -indicatorsize 0
    $addList configure -show tree -style List.Treeview
    $addList column #0 -anchor w -stretch true
    ttk::scrollbar .addForm.addListFrame.scrolly -orient vertical \
        -command {.addForm.addListFrame.addList yview}
    ttk::frame .addForm.controlsFrame
    ttk::button .addForm.controlsFrame.addButton -text Add \
        -compound left -image [form::icon list-add.svg $::ICON_SIZE] \
        -command { gui_add::on_add } -underline 0
    ttk::label .addForm.controlsFrame.addLabel -text "All selected\
        files will be added;\nall unselected files will be ignored." \
        -wraplength 100p
    ttk::button .addForm.controlsFrame.closeButton -text Cancel \
        -compound left -image [form::icon close.svg $::ICON_SIZE] \
        -command { gui_add::on_close }
}


proc gui_add::make_layout {} {
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


proc gui_add::make_bindings {} {
    bind .addForm <Alt-a> { gui_add::on_add }
    bind .addForm <Escape> { gui_add::on_close }
}

proc gui_add::populate {{store_filename ""} {names ""}} {
    if {$store_filename ne ""} {
        set ::gui_add::StoreFilename $store_filename
    }
    if {[winfo exists .addForm]} {
        set addList .addForm.addListFrame.addList
        $addList delete [$addList children {}]
        if {![llength $names]} {
            set str [Store new $::gui_add::StoreFilename]
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

proc gui_add::on_add {} {
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
        set str [Store new $::gui_add::StoreFilename]
        try {
            if {[llength $addable]} { $str add {*}$addable }
            if {[llength $ignores]} { $str ignore {*}ignores }
        } finally {
            $str destroy
        }
        on_close
    }
}

proc gui_add::on_close {} {
    form::hide .addForm
    {*}$::gui_add::Refresh
}
