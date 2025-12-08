# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ctext 3
package require gui_highlight
package require ntext 1
package require scrollutil_tile 2
package require ui

namespace eval gui_misc {
    variable Ext ""
}

proc gui_misc::make_text_frame {} {
    set tf [ttk::frame .textFrame]
    set name text
    set sa [scrollutil::scrollarea $tf.sa]
    set txt [ctext $tf.sa.$name -wrap none -undo true -font Mono \
             -linemapbg gray90]
    $sa setwidget $txt
    pack $sa -fill both -expand 1
    bindtags $txt {$txt Ntext . all}
    $txt tag configure sel -selectbackground yellow
    list $tf $txt
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
            .sql { gui_highlight::highlight_sql $txt }
        }
    }
}
