#!/usr/bin/env perl

use strict; 
use warnings;
use lib qw(../lib);
use FLAT::DFA; use FLAT::NFA; use FLAT::PFA; use FLAT::Regex::WithExtraOps;
use Data::Dumper;
use Tie::Hash::Indexed; # required to test algorithm, since perl hashes are not ordered

my $DEBUG = 0;

my $dfa = FLAT::Regex::WithExtraOps->new('a')->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

# creates ordered hash ref for nested, ordered hashes needed to test various scenarios
sub tieH {
  tie my %hash, 'Tie::Hash::Indexed', @_;
  return \%hash;
}

tie my %testnodelist, 'Tie::Hash::Indexed';
   %testnodelist = (0 => tieH( 1 => 'a',    # finite
                               4 => 'd',    # finite
                               7 => 'g',    # infinite
                              12 => 'o'),   # infinte 
                    1 => { 2 => 'b', },
                    2 => { 3 => 'c', },
                    3 => { },
                    4 => { 5 => 'e', },
                    5 => { 6 => 'f', },
                    6 => { },
                    7 => { 8 => 'h' },
                    8 => { 9 => 'i' },
                    9 => tieH( 9 => 'l',    # self-loop
                              10 => 'j',
                               2 => 'n'),   # supposed to be a cross edge
                   10 => tieH( 8 => 'k',
                              11 => 'm'),
                   11 => { },
                   12 => { 13 => 'p',},
                   13 => { 14 => 'q',},
                   14 => { 15 => 'r',},
                   15 => tieH(15 => 's',
                              13 => 'u',
                               5 => 't'),   # supposed to be a cross edge 
                   );

# secondary DFT over forest, of which each k-group
# is a root node; all nodes not in a k-group, accessible
# from a k-group is also in K
sub pass2 {

}

# builds a new directed graph taking all nodes in
# each k-group to be their own node
sub consolidate {

}

{ ### closure to moderate access and modification to $TAINT and $lastDFLabel
  my $lastDFLabel = 0; 
  sub next_dflabel { return ++$lastDFLabel;}
  sub get_dflabel  { return $lastDFLabel;}
  my $TAINTED = 0;
  sub toggle_taint_on  { $TAINTED = $TAINTED*-1+1; print STDERR "taint ON:  $TAINTED\n" if ($DEBUG); }
  sub toggle_taint_off { $TAINTED = $TAINTED*-1;   print STDERR "taint OFF: $TAINTED\n" if ($DEBUG); }
  sub get_taint { return $TAINTED; }
}

sub pk_partition {
  my $dfa         = shift;
  my %nodelist    = %testnodelist; # $dfa->as_node_list(); 
  my %dflabel     = (); # tracks dflabel 
  my %backtracked = (); # tracks nodes from which we've backtracked for cross edge detection
  my %taintpoints = (); # tracks taint points
  my %kgroups     = (); # strong components + nodes reachable via them
  my %crossedges  = (); # tracks cross edges to check 
  pass1($dfa->get_starting(),\%nodelist,\%dflabel,\%backtracked,\%taintpoints,\%kgroups,\%crossedges);
  print STDERR Dumper(\%kgroups);
  %nodelist = consolidate(\%nodelist,\%kgroups,\%crossedges);
  pass2()
}

# initial DFT, detecting strong components *and*
# the nodes which are accessible by them
sub pass1 {
  my $startNode   = shift;
  my $nodelist    = shift;
  my $dflabel     = shift; # tracks dflabel 
  my $backtracked = shift; # tracks nodes from which we've backtracked for cross edge detection
  my $taintpoints = shift; # tracks taint points
  my $kgroups     = shift; # strong components + nodes reachable via them
  my $crossedges  = shift; # tracks cross edges to check 

  print STDERR "start node: $startNode\n" if ($DEBUG);

  # getting here indicates the following of an edge to a previously unvisited node, $startNode
  $dflabel->{$startNode} = next_dflabel(); 
  if (0 < get_taint()) {
    $kgroups->{get_taint()}->{$startNode}++;                   # add startNode to current kgroup if in taint-mode
  }
  # attempt to continue traversal on $startNode's adjacent nodes (all via edge directed outward)
  foreach my $adjacent (keys(%{$nodelist->{$startNode}})) {
    if (!exists($dflabel->{$adjacent})) {                      # follow tree edge (recursively call pass1(...))
      pass1($adjacent,$nodelist,$dflabel,$backtracked,$taintpoints,$kgroups,$crossedges);
      # on back track
      $backtracked->{$adjacent}++;                             # track for cross edge detection
      print STDERR "back tracked from: $adjacent\n" if ($DEBUG);
      if (0 < get_taint()) {                                   # only check if in taint-mode 
        $kgroups->{get_taint()}->{$adjacent}++;                # add adjacent to current kgroup
        if (exists($taintpoints->{$adjacent})) {               # remove $startNode from $taintpoints if it's a member
          delete($taintpoints->{$adjacent});
        }
        # check to see if there are no more taintpoints
        if (!keys(%{$taintpoints})) {                          # taint-mode is off only if $taintpoints is empty
           print STDERR "taint points empty\n" if ($DEBUG); 
           toggle_taint_off();
        }
      }
    } elsif ($dflabel->{$adjacent} == $dflabel->{$startNode}) {
      print STDERR "self loop: $startNode -> $adjacent\n" if ($DEBUG);
      if (0 >= get_taint()) {
        toggle_taint_on();
      }
      $taintpoints->{$adjacent}++;                             # track points at which back edges are detected
    } else {                                                   # adjacent is a previously visited node
      if ($dflabel->{$adjacent} < $dflabel->{$startNode}) {
        if (!exists($backtracked->{$adjacent})) {              # adjacent is a back edge 
          print STDERR "back edge: $startNode -> $adjacent\n" if ($DEBUG);
          if (0 >= get_taint()) {
            toggle_taint_on();
          }
          # the following is not dependent on the condition, 0>=$TAINTED
          $taintpoints->{$adjacent}++;                         # track points at which back edges are detected
          $kgroups->{get_taint()}->{$adjacent}++;              # add adjacent to current kgroup
        } else {                                               # adjacent is a cross edge
          $crossedges->{$startNode}->{$adjacent}++;
          print STDERR "cross edge: $startNode -> $adjacent\n" if ($DEBUG);
        }
      }
    }
  } # end adjacent for loop
}

my (@P,@K) = pk_partition($dfa);

1;
