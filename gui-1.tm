# Copyright © 2025 Mark Summerfield. All rights reserved.

package require gui_app
package require store

namespace eval gui {}

proc gui::main {} {
    wishinit
    tk appname Store
    set app [App new]
    $app show
}

proc gui::wishinit {} {
    catch {
        set fh [open [file join [file home] .wishinit.tcl]]
        set raw [read $fh]
        close $fh
        eval $raw
    }
    set ::LINEHEIGHT [expr {[font metrics font -linespace] * 1.0125}]
    ttk::style configure Treeview -rowheight $::LINEHEIGHT
    ttk::style configure TCheckbutton -indicatorsize \
        [expr {$::LINEHEIGHT * 0.75}]
    set ::ICON_SIZE [expr {max(24, round(20 * [tk scaling]))}]
}
