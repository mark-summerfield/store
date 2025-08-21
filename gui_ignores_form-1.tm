# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require lambda 1
package require store
package require ui

namespace eval gui_ignores_form {}

proc gui_ignores_form::show_modal {store_filename refresh} {
    set ::gui_ignores_form::Refresh $refresh
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

proc gui_ignores_form::on_show {} {
    set ignoresList .ignoresForm.ignoresListFrame.ignoresList
    if {![llength [$ignoresList selection]]} {
        set first [lindex [$ignoresList children {}] 0]
        $ignoresList see $first
        $ignoresList selection set $first
        $ignoresList focus $first
    }
}

proc gui_ignores_form::make_widgets {} {
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
        -command { gui_ignores_form::on_add } -underline 0
    ttk::entry .ignoresForm.controlsFrame.addEntry -width 12
    ttk::button .ignoresForm.controlsFrame.deleteButton -text Delete \
        -compound left \
        -image [ui::icon list-remove.svg $::ICON_SIZE] \
        -command { gui_ignores_form::on_delete } -underline 0
    ttk::button .ignoresForm.controlsFrame.closeButton -text Close \
        -compound left -image [ui::icon close.svg $::ICON_SIZE] \
        -command { gui_ignores_form::on_close }
}


proc gui_ignores_form::make_layout {} {
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


proc gui_ignores_form::make_bindings {} {
    bind .ignoresForm.controlsFrame.addEntry <Return> {
        gui_ignores_form::on_add
    }
    bind .ignoresForm <Alt-a> { gui_ignores_form::on_add }
    bind .ignoresForm <Alt-d> { gui_ignores_form::on_delete }
    bind .ignoresForm <Escape> { gui_ignores_form::on_close }
}

proc gui_ignores_form::populate {{store_filename ""}} {
    if {$store_filename ne ""} {
        set ::gui_ignores_form::StoreFilename $store_filename
    }
    if {[winfo exists .ignoresForm]} {
        set ignoresList .ignoresForm.ignoresListFrame.ignoresList
        $ignoresList delete [$ignoresList children {}]
        set str [Store new $::gui_ignores_form::StoreFilename]
        try {
            foreach ignore [$str ignores] {
                $ignoresList insert {} end -text $ignore
            }
        } finally {
            $str destroy
        }
    }
}

proc gui_ignores_form::on_add {} {
    if {[winfo exists .ignoresForm]} {
        set txt [.ignoresForm.controlsFrame.addEntry get]
        if {$txt eq ""} {
            focus .ignoresForm.controlsFrame.addEntry
        } else {
            set str [Store new $::gui_ignores_form::StoreFilename]
            try {
                $str ignore $txt
                populate
            } finally {
                $str destroy
            }
        }
    }
}

proc gui_ignores_form::on_delete {} {
    if {[winfo exists .ignoresForm]} {
        set ignoresList .ignoresForm.ignoresListFrame.ignoresList
        set item [$ignoresList selection]
        if {$item ne {}} {
            set index [expr {[$ignoresList index $item] - 1}]
            set str [Store new $::gui_ignores_form::StoreFilename]
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

proc gui_ignores_form::on_close {} {
    form::hide .ignoresForm
    {*}$::gui_ignores_form::Refresh
}
