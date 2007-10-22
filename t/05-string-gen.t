use Test::More 'no_plan';

use strict;

use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use FLAT::Regex::Util;

for (1..100) {
  my $PRE = FLAT::Regex::Util::random_pre(8);
  #diag($PRE->as_string);
  my $DFA = $PRE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
  my $next = $DFA->new_acyclic_string_generator();
  while (my $string = $next->()) {
    ok( $DFA->is_valid_string($string) );
  }
  
  $next = $DFA->new_deepdft_string_generator();
  for (1..10) {
    while (my $string = $next->()) {
      ok( $DFA->is_valid_string($string) );
      last;
    }
  }
  
  $next = $DFA->new_deepdft_string_generator(5);
  for (1..10) {
    while (my $string = $next->()) {
      ok( $DFA->is_valid_string($string) );
      last;
    }
  }
}
