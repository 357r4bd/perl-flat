#!/bin/sh

# profile FLAT code

# Usage:
#
# ./profile.sh <dev-script-name> [arg1 arg2 ... argN]

# run with Dprof as debugger
perl -d:DProf $@
# process tmon.out file
dprofpp
