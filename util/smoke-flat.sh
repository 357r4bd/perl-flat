#!/bin/sh

cd ../tinderbox

for tinder in `ls -1`; do
  OK=0
  perl $tinder && OK=1
  if [ $OK -eq 0 ]; then
    echo Oops...problem in $tinder
    exit 1
  fi
done
