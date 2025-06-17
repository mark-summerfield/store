#!/usr/bin/env tclsh9
# Copyright © 2025 Mark Summerfield. All rights reserved.

package require rcs
package require struct::list 1

proc lcs_test {} {
    global A B C D E F G H
    set diff [to_diff $A $B]
    puts "diff=$diff"
}

proc to_diff {a b} {
    set lcs [struct::list longestCommonSubsequence $a $b]
    set diff [list]
    foreach lst [struct::list lcsInvert $lcs [string length $a] \
                                             [string length $b]] {
        switch [lindex $lst 0] {
            added {set action +}
            deleted {set action -}
            changed {set action %}
        }
        lappend diff "$action [lindex $lst 1] [lindex $lst 2]"
    }
    return $diff
}

proc rcs_test {} {
    global A B C D E F G H
    set pcl [to_pcl $A]
    puts $pcl
}

proc to_pcl text {
    set d [rcs::text2dict $text]
    puts "d=$d"
    catch {
        set p [rcs::decodeRcsPatch $text]
        puts "decodeRcsPatch=$p"
    } p
    puts $p
    catch {
        set p [rcs::encodeRcsPatch $text]
        puts "encodeRcsPatch=$p"
    } p
    puts $p
    return $p
}

const A "foo\nbar\nbaz\nquux"
const B	"foo\nbaz\nbar\nquux"
# Expect:
# = foo
# + baz
# = bar
# - baz
# = quux

const C "the quick brown fox jumped over the lazy dogs"
const D "a quick red fox jumped over some lazy hogs"
# Expect:
# % a
# = quick
# % red
# = fox jumped over
# % some
# = lazy
# % hogs

const E "the quick brown fox jumped over the lazy dogs"
const F "a quick red fox jumped over some lazy hogs"
# Expect:
# - the
# + a
# - brown
# + red
# - the
# + some
# - dogs
# + hogs

const G "the quick brown fox\njumped over the lazy dogs\n"
const H "a quick red fox\njumped over some lazy hogs\n"
# Expect:
# - the
# + a
# - brown
# + red
# - the
# + some
# - dogs
# + hogs

#rcs_test
lcs_test
