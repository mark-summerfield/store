# Copyright © 2025 Mark Summerfield. All rights reserved.

package require autoscroll 1
package require ntext 1

namespace eval gui_misc {}

proc gui_misc::make_text_frame {} {
    set textFrame [ttk::frame .textFrame]
    set txt [text .textFrame.text -wrap word \
        -yscrollcommand {.textFrame.scrolly set} -font Mono]
    bindtags $txt {$txt Ntext . all}
    $txt tag configure sel -selectbackground yellow
    ttk::scrollbar .textFrame.scrolly -orient vertical \
        -command {.textFrame.text yview}
    pack .textFrame.scrolly -side right -fill y -expand true
    pack .textFrame.text -side left -fill both -expand true
    autoscroll::autoscroll .textFrame.scrolly
    list $textFrame $txt
}

proc gui_misc::set_tree_tags tree {
    $tree tag configure parent -foreground blue
    $tree tag configure untracked -foreground gray
    $tree tag configure generation -foreground green
    $tree tag configure updatable -foreground red
}
