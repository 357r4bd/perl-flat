#!/bin/env perl

use strict;

use lib '..';
use FLAT::Symbol::Regex;
use Data::Dumper;

my @regexes=('a', 'a+b', 'a*', 'a*+b', 'a*+b*', 'a(b)*+c', '[dog]*+[cat]', '',' ');
print join(",",@regexes),"\n";

my $x = 50;
my $symbol = undef;

for my $s (@regexes) {
  $symbol = FLAT::Symbol::Regex->new($s);
  print $symbol->as_string,"\n";
  for (1..$x) {
    $symbol->_increment_count;
    #    print $symbol->get_count,"\n"; 
  }
  for (my $i=$x; $i >= 0; $i--) {
    $symbol->_decrement_count;
    #    print $symbol->get_count,"\n"; 
  }
  print Dumper($symbol);
}


print "We should see an error now\n";
$symbol->_decrement_count;


1;
