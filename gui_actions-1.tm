# Copyright © 2025 Mark Summerfield. All rights reserved.

package require diff

namespace eval gui_actions {}

proc gui_actions::diff {store_filename txt in_context set_status_info \
                        new_gid old_gid filename} {
    set str [Store new $store_filename]
    try {
        if {$new_gid} {
            lassign [$str get $new_gid $filename] _ new_data
        } else {
            if {![file exists $filename]} {
                {*}$set_status_info "can't diff \"$filename\"; not found\
                        on disk" $::SHORT_WAIT
                return
            }
            set new_data [readFile $filename binary]
        }
        if {!$old_gid} {
            set old_gid [$str current_generation]
        }
        lassign [$str get $old_gid $filename] gid old_data
    } finally {
        $str destroy
    }
    if {!$gid} {
        {*}$set_status_info "can't diff @$old_gid \"$filename\"; not\
                present in that generation" $::SHORT_WAIT
        return
    }
    set old_data [split [encoding convertfrom utf-8 $old_data] \n]
    set new_data [split [encoding convertfrom utf-8 $new_data] \n]
    set delta [diff::diff $old_data $new_data]
    if {$in_context} { set delta [diff::contextualize $delta] }
    diff::diff_text $delta $txt
}
