#!/usr/bin/env perl
use strict;
use warnings;

use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $PRE = "abc&(def)*";
my $dfa = FLAT::Regex::WithExtraOps->new($PRE)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

my $next = $dfa->new_acyclic_string_generator;

print "PRE: $PRE\n";
print "Acyclic:\n";
while (my $string = $next->()) {
  print "  $string\n";
}

$next = $dfa->new_deepdft_string_generator();
print "Deep DFT (default):\n";
for (1..10) {
  while (my $string = $next->()) {
    print "  $string\n";
    last;
  }
}

$next = $dfa->new_deepdft_string_generator(5);
print "Deep DFT (5):\n";
for (1..10) {
  while (my $string = $next->()) {
    print "  $string\n";
    last;
  }
}
