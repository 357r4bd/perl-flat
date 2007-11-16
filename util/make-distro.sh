#!/bin/sh

OK=0

mkdir FLAT-$$                 &&\
cp -r ../lib FLAT-$$          &&\
cp -r ../t FLAT-$$            &&\
cp -r ../MANIFEST FLAT-$$     &&\
cp -r ../Makefile.PL FLAT-$$  &&\
cp -r ../bin FLAT-$$          &&\
cd FLAT-$$                    &&\
perl Makefile.PL              &&\
make test                     &&\
make clean                    &&\
cd ..                         &&\
tar -v --exclude=.svn --exclude=*~  --create --file=- FLAT-$$ | gzip -c > FLAT-$$.tar.gz

echo things look ok, let\'s check    &&\
rm -rf FLAT-$$                       &&\
gunzip -c FLAT-$$.tar.gz | tar xvf - &&\
cd FLAT-$$                           &&\
perl Makefile.PL                     &&\
make test && cd .. && rm -rf FLAT-$$ && OK=1

if [ $OK -eq 1 ]; then
  echo things look ok
else
  echo things broke
fi
