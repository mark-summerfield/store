#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v Variable.*is.never.read
./test_store.tcl
du -sh .git
ls -sh .store.str
clc -s -l tcl
git st
