use Test::More 'no_plan';

use strict;

use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

# w&w
my $PFA1 = FLAT::Regex::WithExtraOps->new('abc&def')->as_pfa();
my $PFA2 = FLAT::Regex::WithExtraOps->new('a(b(c&def)+d(ef&bc))+d(ef&abc)')->as_pfa();
my $DFA1 = $PFA1->as_nfa->as_min_dfa;
my $DFA2 = $PFA2->as_nfa->as_min_dfa;

is( ($DFA1->equals($DFA2)), 1 );

$DFA1->trim_sinks;
my $next = $DFA1->new_acyclic_string_generator();
while (my $string = $next->()) {
  ok( $DFA1->is_valid_string($string) );
}

$DFA1= FLAT::Regex::WithExtraOps->new('abc&(def)*')->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

$next = $DFA1->new_acyclic_string_generator();
while (my $string = $next->()) {
  ok( $DFA1->is_valid_string($string) );
}

$next = $DFA1->new_deepdft_string_generator();
for (1..10) {
  while (my $string = $next->()) {
    ok( $DFA1->is_valid_string($string) );
    last;
  }
}

$next = $DFA1->new_deepdft_string_generator(5);
for (1..10) {
  while (my $string = $next->()) {
    ok( $DFA1->is_valid_string($string) );
    last;
  }
}
