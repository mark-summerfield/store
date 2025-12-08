# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require lambda 1
package require store
package require ui

oo::singleton create IgnoresForm {
    superclass AbstractForm

    variable Refresh
    variable StoreFilename
    variable IgnoresList
}

oo::define IgnoresForm constructor {} {
    toplevel .ignoresForm
    wm title .ignoresForm "[tk appname] — Ignores"
    my make_widgets
    my make_layout
    my make_bindings
    wm minsize .ignoresForm 480 320
    next .ignoresForm [callback on_close]
}

oo::define IgnoresForm method show {store_filename refresh} {
    set StoreFilename $store_filename
    set Refresh $refresh
    my populate $StoreFilename
    .ignoresForm.controlsFrame.addEntry delete 0 end
    my show_modal $IgnoresList
    my on_show
}

oo::define IgnoresForm method on_show {} {
    if {![llength [$IgnoresList selection]]} {
        set first [lindex [$IgnoresList children {}] 0]
        $IgnoresList see $first
        $IgnoresList selection set $first
        $IgnoresList focus $first
    }
}

oo::define IgnoresForm method make_widgets {} {
    set frm [ttk::frame .ignoresForm.ignoresListFrame]
    set name ignoresList
    ttk::style configure List.Treeview.Item -indicatorsize 0
    set sa [scrollutil::scrollarea $frm.sa -xscrollbarmode none]
    set IgnoresList [ttk::treeview $frm.sa.$name -striped true -show tree \
        -selectmode browse -style List.Treeview]
    $sa setwidget $IgnoresList
    pack $sa -fill both -expand 1
    $IgnoresList column #0 -anchor w -stretch true
    ttk::frame .ignoresForm.controlsFrame
    ttk::button .ignoresForm.controlsFrame.addButton -text Add: \
        -compound left -image [ui::icon list-add.svg $::ICON_SIZE] \
        -command [callback on_add] -underline 0
    ttk::entry .ignoresForm.controlsFrame.addEntry -width 12
    ui::apply_edit_bindings .ignoresForm.controlsFrame.addEntry
    ttk::button .ignoresForm.controlsFrame.deleteButton -text Delete \
        -compound left -image [ui::icon list-remove.svg $::ICON_SIZE] \
        -command [callback on_delete] -underline 0
    ttk::button .ignoresForm.controlsFrame.closeButton -text Close \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command [callback on_close]
}


oo::define IgnoresForm method make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    set form .ignoresForm
    set frm $form.ignoresListFrame
    grid $frm -row 0 -column 0 -sticky news
    grid $frm.sa -row 0 -column 0 -sticky news
    grid columnconfigure $frm 0 -weight 9
    grid rowconfigure $frm 0 -weight 1
    set frm $form.controlsFrame
    grid $frm -row 0 -column 1 -sticky ns
    pack $frm.addButton -side top {*}$opts
    pack $frm.addEntry -side top -fill x {*}$opts
    pack $frm.deleteButton -side top {*}$opts
    pack $frm.closeButton -side bottom {*}$opts
    grid rowconfigure $form 0 -weight 1
    grid columnconfigure $form 0 -weight 1
}


oo::define IgnoresForm method make_bindings {} {
    bind .ignoresForm.controlsFrame.addEntry <Return> [callback on_add]
    bind .ignoresForm <Alt-a> [callback on_add ]
    bind .ignoresForm <Alt-d> [callback on_delete]
    bind .ignoresForm <Escape> [callback on_close]
}

oo::define IgnoresForm method populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set StoreFilename $store_filename
    }
    $IgnoresList delete [$IgnoresList children {}]
    set str [Store new $StoreFilename]
    try {
        foreach ignore [$str ignores] {
            $IgnoresList insert {} end -text $ignore
        }
    } finally {
        $str destroy
    }
}

oo::define IgnoresForm method on_add {} {
    set txt [.ignoresForm.controlsFrame.addEntry get]
    if {$txt eq ""} {
        focus .ignoresForm.controlsFrame.addEntry
    } else {
        set str [Store new $StoreFilename]
        try {
            $str ignore $txt
            my populate
        } finally {
            $str destroy
        }
    }
}

oo::define IgnoresForm method on_delete {} {
    set item [$IgnoresList selection]
    if {$item ne {}} {
        set index [expr {[$IgnoresList index $item] - 1}]
        set str [Store new $StoreFilename]
        try {
            $str unignore [$IgnoresList item $item -text]
            my populate
        } finally {
            $str destroy
        }
        if {$index < 0 && ![llength [$IgnoresList selection]]} {
            set index 0
        }
        if {$index >= 0} {
            set item [lindex [$IgnoresList children {}] $index]
            $IgnoresList see $item
            $IgnoresList selection set $item
            $IgnoresList focus $item
        }
    }
}

oo::define IgnoresForm method on_close {} {
    my hide
    {*}$Refresh
}
