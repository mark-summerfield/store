#!/bin/bash
nagelfar.sh \
    | grep -v Unknown.command..app::main
./test_store.tcl
clc -s -l tcl
git st
