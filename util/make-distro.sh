#!/bin/sh

mkdir FLAT-$$                 &&\
cp -r ../lib FLAT-$$          &&\
cp -r ../t FLAT-$$            &&\
cp -r ../MANIFEST FLAT-$$     &&\
cp -r ../Makefile.PL FLAT-$$  &&\
cp -r ../bin FLAT-$$

find FLAT-$$/ -name ".svn" -exec rm -rf {} \;
tar cvf - FLAT-$$ | gzip -c > FLAT-$$.tar.gz
