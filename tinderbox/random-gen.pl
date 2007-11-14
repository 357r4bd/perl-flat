use Test::More 'no_plan';

use strict;
use lib "../lib";

use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use FLAT::Regex::Util;

for (my $size = 1; $size <=16; $size++) {
  for (1..1000) {
    my $PRE = FLAT::Regex::Util::random_pre($size);
    print $PRE->as_string,"\n";
    my $DFA = $PRE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
  }
}
