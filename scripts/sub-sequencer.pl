#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;

# Regex minus Kleene* until we figure out ?
use FLAT::Regex::WithExtraOps;

#
# Demonstration of using PREs to *easily* generate a 'sequentially consistent' ordering
# of symbols expressed with concurrent semantics
#
# WHY?
#  + expressing concurrency is easy for humans,
#  - programming concurrently is hard for humans
#  + programming sequentially is easy is accessible for humans,
#  - programming concurrency sequentially is very *HARD* for humans
#
# SO, WHAT?
#  + express it concurrently using a Regular Language+shuffle (and maybe other ops closed under REs)
#  + convert to a uniprocess, run in an inherently sequential environment
#

#
# STEP 1: H I G H "PARALLEL" L E V E L  D E S C R I P T I O N
#

# high level description of concurrency
my $pre = q{
  [ begin]
    (
      [ seq_subA]
      (
        [ seq_subB_a]
        [ seq_subB_b]
      )
      [ seq_subC]
    &
      [ seq_subD]
      [ seq_subE]
      [ seq_subF]
    )
  [ end]
};

# initialize "sequential compiler" - i.e., a minified DFA
my $dfa = FLAT::Regex::WithExtraOps->new($pre)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

# get one of potentially *many* strings accepted by DFA (here using a lazy iterator)
my $iter = $dfa->init_acyclic_iterator(); # useful for PREs with no kleene star
my $consistent_sequence = $iter->();

# 
$consistent_sequence =~ s/^ //g; #tromp LOL!!
my @consistent_sequence = split / /, $consistent_sequence;

## Useful to dump sub routine stubs for that correspond to the 'symbols' above
#  useful to create an idiomatic starting point
#

print qq[#!/usr/bin/env perl
#
# + each sub has a persistent memory (\$my_state)
# + each sub has a call-time scope scratch pad memory (\$my_scratch)
#
# Original sequence: $consistent_sequence;
package main;
my \$global_state = {};
];

foreach my $sub (@consistent_sequence) {
  print qq/sub $sub {
    state \$my_state   = {};
    local \$my_scratch = {};

    print qq{$sub\\n};
    return q{$sub};
}
\n/;
}

#
# STEP 2: R U N "SEQUENTIAL ORDERING" S E Q U E N T I A L L Y
#

# run loop (here, just one pass; but all of this is Perl so we can do all kinds of stuff!!! :-))
#foreach my $sub () {
#    # just a 'string form' of 'eval'
#    eval 'main::$sub';  
#}

1;

__END__
