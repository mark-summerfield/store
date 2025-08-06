# Copyright © 2025 Mark Summerfield. All rights reserved.

package require gui_app
package require gui_app_actions
package require gui_app_make
package require gui_globals
package require gui_misc
package require inifile
package require ui

namespace eval gui {}

proc gui::main {} {
    ui::wishinit
    tk appname Store
    set configFilename [read_config]
    make_fonts
    set app [App new $configFilename]
    $app show
}

proc gui::read_config {} {
    const filename [ui::get_ini_filename]
    set family [font configure TkFixedFont -family]
    set size [expr {1 + [font configure TkFixedFont -size]}]
    if {[file exists $filename] && [file size $filename]} {
        set ini [ini::open $filename -encoding utf-8 r]
        try {
            if {[ini::exists $ini Window]} {
                set geometry [ini::value $ini Window Geometry ""]
                if {$geometry ne ""} {
                    wm geometry . $geometry
                }
                set family [ini::value $ini Window FontFamily $family]
                set size [ini::value $ini Window FontSize $size]
            }
        } finally {
            ini::close $ini
        }
    }
    font create Mono -family $family -size $size
    return $filename
}

proc gui::make_fonts {} {
    font create H1 -family [font configure TkTextFont -family] \
        -size [expr {3 + [font configure TkTextFont -size]}] -weight bold
}
