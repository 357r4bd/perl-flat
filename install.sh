#!/bin/sh
perl Makefile.PL && \
            make && \
       make install && \
       make test
