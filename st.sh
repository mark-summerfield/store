#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v Variable.*is.never.read
echo --- Tests ---
./test_store.tcl
echo -------------
du -sh .git
ls -sh .store.str
clc -s -l tcl
str status
git st
