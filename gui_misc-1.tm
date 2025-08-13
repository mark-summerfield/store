# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ctext 3
package require gui_highlight
package require ntext 1
package require ui

namespace eval gui_misc {
    variable Ext ""
}

proc gui_misc::make_text_frame {} {
    set frame [ttk::frame .textFrame]
    set name text
    set txt [ctext $frame.$name -wrap none -undo true -font Mono \
             -linemapbg gray90]
    ui::scrollize $frame $name both
    bindtags $txt {$txt Ntext . all}
    $txt tag configure sel -selectbackground yellow
    list $frame $txt
}

proc gui_misc::set_tree_tags tree {
    foreach {tag color} {parent blue untracked gray generation green \
                         updatable red} {
        $tree tag configure $tag -foreground $color
    }
}

proc gui_misc::refresh_highlighting {txt ext} {
    if {$ext ne $::gui_misc::Ext} {
        set ::gui_misc::Ext $ext
        ctext::clearHighlightClasses $txt
        switch $ext {
            .tcl - .tm { gui_highlight::highlight_tcl $txt }
        }
    }
}
