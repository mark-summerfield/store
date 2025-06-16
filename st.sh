#!/bin/bash
clc -s -l tcl
nagelfar.sh \
    | grep -v Unknown.command..app::main
git st
