#!/usr/bin/env perl -l
use strict;

use lib qw(../lib);
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

my $next = $dfa->new_acyclic_string_generator;

while (my $string = $next->()) {
  print "$string";
}

my $next = $dfa->new_deepdft_string_generator(10);

while (my $string = $next->()) {
  print "$string";
}
