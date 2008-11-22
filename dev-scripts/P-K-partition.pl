#!/usr/bin/env perl

use strict; 
use warnings;
use lib qw(../lib);
use FLAT::DFA; use FLAT::NFA; use FLAT::PFA; use FLAT::Regex::WithExtraOps;
use Data::Dumper;
use Tie::Hash::Indexed; # required to test algorithm, since perl hashes are not ordered
use Data::Dumper;

my $DEBUG = 0;

my $trouble_re = 'abc(d)*e'; # so simple, yet so troublesome

my $dfa = FLAT::Regex::WithExtraOps->new($trouble_re)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

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

{ 
  ### closure to moderate access and modification to $TAINT and $lastDFLabel
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
  #my %nodelist   =  $dfa->as_node_list(); 
  my %dflabel     = (); # tracks dflabel 
  my %backtracked = (); # tracks nodes from which we've backtracked for cross edge detection
  my %taintpoints = (); # tracks taint points
  my %kgroups     = (); # strong components + nodes reachable via them
  my %kadj        = (); # nodes adjacent to members of each kgroup
  my %crossedges  = (); # tracks cross edges to check 

  pass1($dfa->get_starting(),undef,\%nodelist,\%dflabel,\%backtracked,\%taintpoints,\%kgroups,\%kadj,\%crossedges);

  trim_kgroup_internal_edges(\%kgroups,\%kadj); # removes all edges to fellow kgroup members, leaving only edges leaving the kgroups

  # faciliate dfs over forest now, starting at the designated edges in %kadj
  my $parent = undef;
  my %kreachable  = (); # will track all non-k nodes reachable by kgroups
  foreach my $k (keys(%kadj)) {
    foreach my $startNode (keys(%{$kadj{$k}})) {
      $parent = $kadj{$k}{$startNode};
      pass2($startNode,$parent,\%nodelist,\%dflabel,\%kreachable);
    }
  }
}

sub trim_kgroup_internal_edges {
  my $kgroups     = shift; # strong components + nodes reachable via them
  my $kadj        = shift; # nodes adjacent to members of each kgroup
  foreach my $k (keys(%{$kgroups})) {
    foreach my $kmember (keys(%{$kgroups->{$k}})) {
      delete($kadj->{$k}->{$kmember}); 
    }
  }
}

# second pass - starting with each k group; the 
# idea is to find all nodes reachable by all k-groups
#
sub pass2 {
  my $startNode   = shift;
  my $parent      = shift;
  my $nodelist    = shift;
  my $dflabel     = shift; # tracks dflabel 
  my $kreachable  = shift;

# ... need to implement this searching

}

# initial DFT, detecting strong components *and*
# the nodes which are accessible by them
sub pass1 {
  my $startNode   = shift;
  my $parent      = shift;
  my $nodelist    = shift;
  my $dflabel     = shift; # tracks dflabel 
  my $backtracked = shift; # tracks nodes from which we've backtracked for cross edge detection
  my $taintpoints = shift; # tracks taint points
  my $kgroups     = shift; # strong components + nodes reachable via them
  my $kadj        = shift; # nodes adjacent to members of each kgroup
  my $crossedges  = shift; # tracks cross edges to check 

  print STDERR "start node: $startNode\n" if ($DEBUG);

  # getting here indicates the following of an edge to a previously unvisited node, $startNode
  $dflabel->{$startNode} = next_dflabel(); 

  if (0 < get_taint()) {
    $kgroups->{get_taint()}->{$startNode}++;                   # add startNode to current kgroup if in taint-mode
    foreach my $ka (keys(%{$nodelist->{$startNode}})) {  # store all nodes adjacent to each node in kgroup
      $kadj->{get_taint()}->{$ka} = $parent; 
    }
  }

  # attempt to continue traversal on $startNode's adjacent nodes (all via edge directed outward)
  foreach my $adjacent (keys(%{$nodelist->{$startNode}})) {
    if (!exists($dflabel->{$adjacent})) {                      # follow tree edge (recursively call pass1(...))
      pass1($adjacent,$startNode,$nodelist,$dflabel,$backtracked,$taintpoints,$kgroups,$kadj,$crossedges);
                                                               # on back track
      $backtracked->{$adjacent}++;                             # track for cross edge detection
      print STDERR "back tracked from: $adjacent\n" if ($DEBUG);
      if (0 < get_taint()) {                                   # only check if in taint-mode 
        $kgroups->{get_taint()}->{$adjacent}++;                # add adjacent to current kgroup
        foreach my $ka (keys(%{$nodelist->{$adjacent}})) {     # store all nodes adjacent to each node in kgroup
          $kadj->{get_taint()}->{$ka} = $startNode; 
        }
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
          $taintpoints->{$adjacent}++;                         # track points at which back edges are detected
          $kgroups->{get_taint()}->{$adjacent}++;              # add adjacent to current kgroup
          foreach my $ka (keys(%{$nodelist->{$adjacent}})) {     # store all nodes adjacent to each node in kgroup
            $kadj->{get_taint()}->{$ka} = $startNode; 
          }
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
