#!/usr/bin/env perl

use strict; use warnings;
use lib qw(../lib);
use FLAT::DFA; use FLAT::NFA; use FLAT::PFA; use FLAT::Regex::WithExtraOps;
use Data::Dumper;

my $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

# secondary DFT over forest, of which each k-group
# is a root node; all nodes not in a k-group, accessible
# from a k-group is also in K
sub pass2 {

}

# builds a new directed graph taking all nodes in
# each k-group to be their own node
sub consolidate {

}

sub pk_partition {
  my $dfa         = shift;
  my %nodelist    = $dfa->as_node_list(); 
  my $lastDFLabel = 0; 
  my $TAINTED     = 0;
  my %dflabel     = (); # tracks dflabel 
  my %backtracked = (); # tracks nodes from which we've backtracked for cross edge detection
  my %taintpoints = (); # tracks taint points
  my %kgroups     = (); # strong components + nodes reachable via them
  my %crossedges  = (); # tracks cross edges to check 
  pass1($dfa->get_starting(),\%nodelist,$lastDFLabel,\%dflabel,\%backtracked,$TAINTED,\%taintpoints,\%kgroups,\%crossedges);
  #...
  %nodelist = consolidate(\%nodelist,\%kgroups,\%crossedges);
  pass2()
}

# initial DFT, detecting strong components *and*
# the nodes which are accessible by them
sub pass1 {
  my $startNode   = shift;
  my $nodelist    = shift;
  my $lastDFLabel = shift; 
  my $dflabel     = shift; # tracks dflabel 
  my $backtracked = shift; # tracks nodes from which we've backtracked for cross edge detection
  my $TAINTED     = shift; # tracks current taint value (i.e., k-group)
  my $taintpoints = shift; # tracks taint points
  my $kgroups     = shift; # strong components + nodes reachable via them
  my $crossedges  = shift; # tracks cross edges to check 
  $dflabel->{$startNode} = ++$lastDFLabel;
  foreach my $adjacent (keys(%{$nodelist})) {
    if (!exists($dflabel->{$adjacent})) {                      # follow tree edge
      pass1($adjacent,$nodelist,$lastDFLabel,$dflabel,$backtracked,$TAINTED,$taintpoints,$kgroups,$crossedges);
    } else {
      print "$adjacent\n";
      if ($dflabel->{$adjacent} < $dflabel->{$startNode}) {
        if (!exists($backtracked->{$adjacent})) {              # back edge !!
          if (0 >= $TAINTED) {
            $TAINTED = $TAINTED*(-1)+1;
          }
          $taintpoints->{$adjacent}++; # track points at which back edges are detected
          $kgroups->{$TAINTED}->{$adjacent}++; 
        } else {                                               # cross edge
          $crossedges->{$startNode}->{$adjacent}++;
        }
      }
    }
  }
  # on back track
  $backtracked->{$startNode} = 1;
  if (exists($taintpoints->{$startNode})) {
    delete($taintpoints->{$startNode});
  }
  # check to see if there are no more taintpoints
  if (!keys(%{$taintpoints})) {
    $TAINTED = $TAINTED*(-1);
  }
}

my (@P,@K) = pk_partition($dfa);

1;
