# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
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
    set config [Config new]
    make_fonts [$config fontfamily] [$config fontsize]
    set app [App new]
    $app show
}

proc gui::make_fonts {family size} {
    catch { font delete H1 Mono MonoBold MonoItalic MonoBoldItalic }
    font create H1 -family [font configure TkTextFont -family] \
        -size [expr {3 + [font configure TkTextFont -size]}] -weight bold
    font create Mono -family $family -size $size
    font create MonoBold -family [font configure Mono -family] \
        -size $size -weight bold
    font create MonoItalic -family [font configure Mono -family] \
        -size $size -slant italic
    font create MonoBoldItalic -family [font configure Mono -family] \
        -size $size -weight bold -slant italic
}
