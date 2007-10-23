#!/bin/sh

host=`hostname`

while [ 1 ]; do
  smokedir=`pwd`
  cd ../
  svn update
  cd $smokedir
  sleep 10
  perl ./smoke.pl || \
    echo "error with perl-flat smoke test found on $host" | mail -s "perl-flat tinderbox failure" estrabd@gmail.com
  echo "perl-flat smoke test completed on $host" # | mail -s "perl-flat tinderbox success" estrabd@gmail.com
done
