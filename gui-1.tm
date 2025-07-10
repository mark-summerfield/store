# Copyright © 2025 Mark Summerfield. All rights reserved.

package require gui_app
package require gui_misc
package require store

namespace eval gui {}

proc gui::main {} {
    wishinit
    set configFilename [read_config]
    tk appname Store
    set app [App new $configFilename]
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
    ttk::style configure TButton -font Helvetica
    set ::ICON_SIZE [expr {max(24, round(16 * [tk scaling]))}]
}

proc gui::read_config {} {
    set configFilename [misc::get_ini_filename]
    set family Courier
    set size [expr {1 + [font configure TkDefaultFont -size]}]
    if {[file exists $configFilename] && [file size $configFilename]} {
        set ini [ini::open $configFilename -encoding utf-8 r]
        try {
            if {[ini::exists $ini $::SECT_WINDOW]} {
                set geometry [ini::value $ini $::SECT_WINDOW \
                              $::KEY_GEOMETRY ""]
                if {$geometry ne ""} {
                    wm geometry . $geometry
                }
                set family [ini::value $ini $::SECT_WINDOW \
                            $::KEY_FONTFAMILY $family]
                set size [ini::value $ini $::SECT_WINDOW \
                          $::KEY_FONTSIZE $size]
            }
        } finally {
            ::ini::close $ini
        }
    }
    font create CommitMono -family $family -size $size
    return $configFilename
}
