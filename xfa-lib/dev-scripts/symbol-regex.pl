#!/bin/env perl

use strict;

use lib '..';
use FLAT::XFA;
use FLAT::PFA;
use FLAT::DFA;
use FLAT::Symbol::Regex;
use Data::Dumper;

my @regexes=('a', 'a+b', 'a*', 'a*+b', 'a*+b*', 'a(b)*+c', '[dog]*+[cat]', 'a&b', 'a*&b', 'a*&b*', '',' ');
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
  #
  # Extract RE object, from FLAT::Symbol::Regex, and do stuff with it, 
  # and exercise the transformations and string pumping 
  #
  #print Dumper($symbol);
  my $DFA = $symbol->{OBJECT}->as_pfa->as_xfa->as_min_dfa;
  my $next = $DFA->new_deepdft_string_generator(5);
  while (my $string = $next->()) {
    print "  $string\n";
  }
}


print "We should see an error now\n";
$symbol->_decrement_count;


1;
