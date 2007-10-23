#!/bin/sh

host=`hostname`
svn update &&        \
  perl ./smoke.pl || \
  echo "error with perl-flat smoke test found" | mail -s "perl-flat tinderbox failure: $host" estrabd@gmail.com
