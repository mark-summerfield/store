#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v Bad.option.-striped.to..ttk::treeview. \
    | grep -v Variable.*is.never.read \
    | grep -v test_store.tcl.*Found.constant..filename
echo --- Tests ---
./test_store.tcl
echo -------------
du -sh .git
ls -sh .store.str
clc -s -l tcl
str status
git st
