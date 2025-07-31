# Copyright © 2025 Mark Summerfield. All rights reserved.

package require form
package require lambda 1
package require misc
package require store

namespace eval gui_ignores {}

proc gui_ignores::show_modal {store_filename refresh} {
    set ::gui_ignores::Refresh $refresh
    if {![winfo exists .ignoresForm]} {
        toplevel .ignoresForm
        wm title .ignoresForm "[tk appname] — Ignores"
        make_widgets
        make_layout
        make_bindings
        wm minsize .ignoresForm 480 320
        set on_close [lambda {} {form::hide .ignoresForm}]
        form::prepare .ignoresForm $on_close false
        populate $store_filename
    }
    .ignoresForm.controlsFrame.addEntry delete 0 end
    form::show_modal .ignoresForm .ignoresForm.ignoresListFrame.ignoresList
    on_show
}

proc gui_ignores::on_show {} {
    set ignoresList .ignoresForm.ignoresListFrame.ignoresList
    if {![llength [$ignoresList selection]]} {
        set first [lindex [$ignoresList children {}] 0]
        $ignoresList see $first
        $ignoresList selection set $first
        $ignoresList focus $first
    }
}

proc gui_ignores::make_widgets {} {
    ttk::frame .ignoresForm.ignoresListFrame
    set ignoresList [ttk::treeview \
        .ignoresForm.ignoresListFrame.ignoresList -striped true \
        -yscrollcommand {.ignoresForm.ignoresListFrame.scrolly set}]
    ttk::style configure List.Treeview.Item -indicatorsize 0
    $ignoresList configure -show tree -selectmode browse \
        -style List.Treeview
    $ignoresList column #0 -anchor w -stretch true
    ttk::scrollbar .ignoresForm.ignoresListFrame.scrolly -orient vertical \
        -command {.ignoresForm.ignoresListFrame.ignoresList yview}
    ttk::frame .ignoresForm.controlsFrame
    ttk::button .ignoresForm.controlsFrame.addButton -text Add: \
        -compound left -image [form::icon list-add.svg $::ICON_SIZE] \
        -command { gui_ignores::on_add } -underline 0
    ttk::entry .ignoresForm.controlsFrame.addEntry -width 12
    ttk::button .ignoresForm.controlsFrame.deleteButton -text Delete \
        -compound left \
        -image [form::icon list-remove.svg $::ICON_SIZE] \
        -command { gui_ignores::on_delete } -underline 0
    ttk::button .ignoresForm.controlsFrame.closeButton -text Close \
        -compound left -image [form::icon close.svg $::ICON_SIZE] \
        -command { gui_ignores::on_close }
}


proc gui_ignores::make_layout {} {
    set opts "-padx $::PAD -pady $::PAD"
    grid .ignoresForm.ignoresListFrame -row 0 -column 0 -sticky news
    grid .ignoresForm.ignoresListFrame.ignoresList -row 0 -column 0 \
        -sticky news
    grid .ignoresForm.ignoresListFrame.scrolly -row 0 -column 1 -sticky ns
    grid columnconfigure .ignoresForm.ignoresListFrame 0 -weight 9
    grid rowconfigure .ignoresForm.ignoresListFrame 0 -weight 1
    autoscroll::autoscroll .ignoresForm.ignoresListFrame.scrolly
    grid .ignoresForm.controlsFrame -row 0 -column 1 -sticky ns
    pack .ignoresForm.controlsFrame.addButton -side top {*}$opts
    pack .ignoresForm.controlsFrame.addEntry -side top -fill x {*}$opts
    pack .ignoresForm.controlsFrame.deleteButton -side top {*}$opts
    pack .ignoresForm.controlsFrame.closeButton -side bottom {*}$opts
    grid rowconfigure .ignoresForm 0 -weight 1
    grid columnconfigure .ignoresForm 0 -weight 1
}


proc gui_ignores::make_bindings {} {
    bind .ignoresForm.controlsFrame.addEntry <Return> {
        gui_ignores::on_add
    }
    bind .ignoresForm <Alt-a> { gui_ignores::on_add }
    bind .ignoresForm <Alt-d> { gui_ignores::on_delete }
    bind .ignoresForm <Escape> { gui_ignores::on_close }
}

proc gui_ignores::populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set ::gui_ignores::StoreFilename $store_filename
    }
    if {[winfo exists .ignoresForm]} {
        set ignoresList .ignoresForm.ignoresListFrame.ignoresList
        $ignoresList delete [$ignoresList children {}]
        set str [Store new $::gui_ignores::StoreFilename]
        try {
            foreach ignore [$str ignores] {
                $ignoresList insert {} end -text $ignore
            }
        } finally {
            $str destroy
        }
    }
}

proc gui_ignores::on_add {} {
    if {[winfo exists .ignoresForm]} {
        set txt [.ignoresForm.controlsFrame.addEntry get]
        if {$txt eq ""} {
            focus .ignoresForm.controlsFrame.addEntry
        } else {
            set str [Store new $::gui_ignores::StoreFilename]
            try {
                $str ignore $txt
                populate
            } finally {
                $str destroy
            }
        }
    }
}

proc gui_ignores::on_delete {} {
    if {[winfo exists .ignoresForm]} {
        set ignoresList .ignoresForm.ignoresListFrame.ignoresList
        set item [$ignoresList selection]
        if {$item ne {}} {
            set index [expr {[$ignoresList index $item] - 1}]
            set str [Store new $::gui_ignores::StoreFilename]
            try {
                $str unignore [$ignoresList item $item -text]
                populate
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
}

proc gui_ignores::on_close {} {
    form::hide .ignoresForm
    {*}$::gui_ignores::Refresh
}
