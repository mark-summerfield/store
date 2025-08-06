# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ntext 1
package require ui

namespace eval gui_misc {}

proc gui_misc::make_text_frame {} {
    set frame [ttk::frame .textFrame]
    set name text
    set txt [text $frame.text -wrap word -font Mono]
    ui::scrollize $frame $name vertical
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
