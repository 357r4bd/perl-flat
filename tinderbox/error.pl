use Test::More 'no_plan';

use strict;
use lib "../lib";

use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use FLAT::Regex::Util;

my $PRE = FLAT::Regex::WithExtraOps->new('1*0111*1*00');
print $PRE->as_string,"\n";
my $DFA = $PRE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
my $next = $DFA->new_acyclic_string_generator();
while (my $string = $next->()) {
  ok( $DFA->is_valid_string($string) );
}
$next = $DFA->new_deepdft_string_generator(2);
while (my $string = $next->()) {
  ok( $DFA->is_valid_string($string) );
}
