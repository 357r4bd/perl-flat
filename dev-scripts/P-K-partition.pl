#!/usr/bin/env perl

use strict; use warnings;
use lib qw(../lib);
use FLAT::DFA; use FLAT::NFA; use FLAT::PFA; use FLAT::Regex::WithExtraOps;
use Data::Dumper;

my $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

# initial DFT, detecting strong components *and*
# the nodes which are accessible by them
sub pass1 {

}

# secondary DFT over forest, of which each k-group
# is a root node; all nodes not in a k-group, accessible
# from a k-group is also in K
sub pass2 {

}

sub pk_partition {
  my @string  = (); 
  my $lastDFLabel = 0; 
  my %nodelist = $dfa->as_node_list(); 
  my %dflabel = (); 
  my %backtracked = (); # tracks nodes from which we've backtracked for cross edge detection
  my %taintpoints = (); # tracks taint points
  my %kgroups = (); # strong components + nodes reachable via them
  my %crossedges = (); # tracks cross edges to check 
}


1;
