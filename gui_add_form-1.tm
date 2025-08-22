# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require lambda 1
package require store
package require ui

oo::singleton create AddForm {
    superclass AbstractForm

    variable Refresh
    variable StoreFilename
}

oo::define AddForm constructor {} {
    toplevel .addForm
    wm title .addForm "[tk appname] — Add Addable"
    my make_widgets
    my make_layout
    my make_bindings
    wm minsize .addForm 480 320
    next .addForm [callback on_close]
}

oo::define AddForm method show {store_filename refresh names} {
    set StoreFilename $store_filename
    set Refresh $refresh
    my populate $StoreFilename $names
    my show_modal .addForm.addListFrame.addList
}

oo::define AddForm method make_widgets {} {
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
        -command [callback on_add] -underline 0
    ttk::label .addForm.controlsFrame.addLabel -text "All selected\
        files will be added;\nall unselected files will be ignored." \
        -wraplength 100p
    ttk::button .addForm.controlsFrame.closeButton -text Cancel \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command [callback on_close]
}

oo::define AddForm method make_layout {} {
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

oo::define AddForm method make_bindings {} {
    bind .addForm <Alt-a> [callback on_add]
    bind .addForm <Escape> [callback on_close]
}

oo::define AddForm method populate {{store_filename ""} {names ""}} {
    if {$store_filename ne ""} {
        set StoreFilename $store_filename
    }
    set addList .addForm.addListFrame.addList
    $addList delete [$addList children {}]
    if {![llength $names]} {
        set str [Store new $StoreFilename]
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

oo::define AddForm method on_add {} {
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
    set str [Store new $StoreFilename]
    try {
        if {[llength $ignores]} { $str ignore {*}$ignores }
        if {[llength $addable]} { $str add {*}$addable }
    } finally {
        $str destroy
    }
    my on_close
}

oo::define AddForm method on_close {} {
    my hide
    {*}$Refresh
}
