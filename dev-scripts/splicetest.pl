#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my @array = qw/0 1 2 3 4 5 6 7 8 9 10/;
printf("%d\n",splice(@array, 5, 1));
print Dumper(@array); 
