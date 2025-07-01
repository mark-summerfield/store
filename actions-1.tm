# Copyright © 2025 Mark Summerfield. All rights reserved.

package require store

namespace eval actions {}

proc actions::add {reporter filename args} {
    puts "TODO add reporter=$reporter store=$filename args=$args"
}

proc actions::update {reporter filename args} {
    puts "TODO update reporter=$reporter store=$filename args=$args"
}

proc actions::extract {reporter filename args} {
    puts "TODO extract reporter=$reporter store=$filename args=$args"
}

proc actions::copy {reporter filename args} {
    puts "TODO copy reporter=$reporter store=$filename args=$args"
}

proc actions::print {filename args} {
    puts "TODO print store=$filename args=$args"
}

proc actions::diff {filename args} {
    puts "TODO diff store=$filename args=$args"
}

proc actions::filenames {filename args} {
    puts "TODO filenames store=$filename args=$args"
}

proc actions::generations {filename args} {
    puts "TODO generations store=$filename args=$args"
}

proc actions::ignore {filename args} {
    puts "TODO ignore store=$filename args=$args"
}

proc actions::ignores filename {
    puts "TODO ignores store=$filename"
}

proc actions::unignore {filename args} {
    puts "TODO unignore store=$filename args=$args"
}

proc actions::purge {filename args} {
    puts "TODO purge store=$filename args=$args"
}
