# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require lambda 1
package require store
package require ui

oo::singleton create IgnoresForm {
    superclass AbstractForm

    variable Refresh
    variable StoreFilename
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
    my show_modal .ignoresForm.ignoresListFrame.ignoresList
    my on_show
}

oo::define IgnoresForm method on_show {} {
    set ignoresList .ignoresForm.ignoresListFrame.ignoresList
    if {![llength [$ignoresList selection]]} {
        set first [lindex [$ignoresList children {}] 0]
        $ignoresList see $first
        $ignoresList selection set $first
        $ignoresList focus $first
    }
}

oo::define IgnoresForm method make_widgets {} {
    set frame [ttk::frame .ignoresForm.ignoresListFrame]
    set name ignoresList
    set ignoresList [ttk::treeview $frame.$name -striped true -show tree \
        -selectmode browse]
    ui::scrollize $frame $name vertical
    ttk::style configure List.Treeview.Item -indicatorsize 0 \
        -style List.Treeview
    $ignoresList column #0 -anchor w -stretch true
    ttk::frame .ignoresForm.controlsFrame
    ttk::button .ignoresForm.controlsFrame.addButton -text Add: \
        -compound left -image [ui::icon list-add.svg $::ICON_SIZE] \
        -command [callback on_add] -underline 0
    ttk::entry .ignoresForm.controlsFrame.addEntry -width 12
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
    set frame $form.ignoresListFrame
    grid $frame -row 0 -column 0 -sticky news
    grid $frame.ignoresList -row 0 -column 0 -sticky news
    grid $frame.scrolly -row 0 -column 1 -sticky ns
    grid columnconfigure $frame 0 -weight 9
    grid rowconfigure $frame 0 -weight 1
    autoscroll::autoscroll $frame.scrolly
    set frame $form.controlsFrame
    grid $frame -row 0 -column 1 -sticky ns
    pack $frame.addButton -side top {*}$opts
    pack $frame.addEntry -side top -fill x {*}$opts
    pack $frame.deleteButton -side top {*}$opts
    pack $frame.closeButton -side bottom {*}$opts
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
    set ignoresList .ignoresForm.ignoresListFrame.ignoresList
    $ignoresList delete [$ignoresList children {}]
    set str [Store new $StoreFilename]
    try {
        foreach ignore [$str ignores] {
            $ignoresList insert {} end -text $ignore
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
    set ignoresList .ignoresForm.ignoresListFrame.ignoresList
    set item [$ignoresList selection]
    if {$item ne {}} {
        set index [expr {[$ignoresList index $item] - 1}]
        set str [Store new $StoreFilename]
        try {
            $str unignore [$ignoresList item $item -text]
            my populate
        } finally {
            $str destroy
        }
        if {$index < 0 && ![llength [$ignoresList selection]]} {
            set index 0
        }
        if {$index >= 0} {
            set item [lindex [$ignoresList children {}] $index]
            $ignoresList see $item
            $ignoresList selection set $item
            $ignoresList focus $item
        }
    }
}

oo::define IgnoresForm method on_close {} {
    my hide
    {*}$Refresh
}
