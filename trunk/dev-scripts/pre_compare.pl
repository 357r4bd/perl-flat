#!/usr/bin/env perl -l
use strict;

use lib qw(../lib);
use FLAT::Regex::WithExtraOps;
use FLAT::PFA;
use Data::Dumper;

# This is mainly my test script for FLAT::FA::PFA.pm

my $PFA1 = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa();
my $PFA2 = FLAT::Regex::WithExtraOps->new($ARGV[1])->as_pfa();

my $DFA1 = $PFA1->as_nfa->as_min_dfa;
my $DFA2 = $PFA2->as_nfa->as_min_dfa;

if ($DFA1->equals($DFA2)) {
  print "MATCH!";
} else {
  print "No Match";
}
