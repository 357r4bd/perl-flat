#!/bin/env perl

use strict;

use lib '../';
use FLAT::Symbol::String;

my $x = 10;
my $s = 'abc';

my $symbol = FLAT::Symbol::String->new($s);
print $symbol->as_string,"\n";
for (1..$x) {
  $symbol->_increment_count;
  #    print $symbol->get_count,"\n"; 
}
for (my $i=$x; $i >= 0; $i--) {
  $symbol->_decrement_count;
  #    print $symbol->get_count,"\n"; 
}
print "We should see an error now\n";
$symbol->_decrement_count;

1;
