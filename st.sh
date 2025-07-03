#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command \
    | grep -v Unknown.variable \
    | grep -v Variable.*is.never.read
./test_store.tcl
clc -s -l tcl
git st
