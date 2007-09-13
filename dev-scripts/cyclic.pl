#!/usr/bin/env perl -l

#
# To be implemented in the main module code soon 
# (minus not the store/retrieve stuff); that is here for the convenience of testing
#
# This code employs a recursive DFS based determination of all acyclic paths, which is 
# pretty darn efficient
#

use strict;
use warnings;
use lib qw(../lib);
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $dfa;

### Caching Mechanism
### Cache PRE's to disk so that they don't have to be recompiled
use Storable;
mkdir "dat" if (! -e "dat");
if (!-e "dat/$ARGV[0].dat") {
  $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
  store $dfa, "dat/$ARGV[0].dat";
} else {
  print STDERR "dat/$ARGV[0].dat found.."; 
  $dfa = retrieve "dat/$ARGV[0].dat";
}
### End Cache Mechanism

my %nodes = $dfa->as_node_list();



### Subroutines
sub main {
  my @path           = (); # scoped, stores path
  my %dflabel        = (); # scoped lookup table for dflable
  my $lastDFLabel    =  0;
  # accepts start node and set of possible goals
  sd_path($dfa->get_starting(),[$dfa->get_accepting()],[@path],\%dflabel,$lastDFLabel); 
}

#
# Bread and butta function - finds all acyclic paths from given start node to 
# a set of goal nodes; all tracking is self contained and no global vars are
# used
#

sub sd_path {
  my $startNode    = shift;
  my $goals_ref    = shift;
  my $path_ref     = shift;
  my $dflabel_ref  = shift;
  my $lastDFLabel  = shift;
  # add start node to path
  push (@{$path_ref},$startNode);
  # only continue if startNode has not been visited yet
  if (!exists($dflabel_ref->{$startNode})) {
    $dflabel_ref->{$startNode} = ++$lastDFLabel; # increment, then assign
    foreach my $adjacent (keys(%{$nodes{$startNode}})) {
      if (!exists($dflabel_ref->{$adjacent})) {   # initial tree edge
	@{$path_ref} = sd_path($adjacent,[@{$goals_ref}],[@{$path_ref}],$dflabel_ref,$lastDFLabel);
	# assumes some base path found
        if ($dfa->array_is_subset([$adjacent],[@{$goals_ref}])) {   
           # handle discovery of an acyclic path to a goal 
	   explore_acycle(@{$path_ref},$adjacent);
	}
      } else { 
        # back edge that lands on an accepting node  
        if ($dfa->array_is_subset([$adjacent],[@{$goals_ref}])) {   
           # handle discovery of an acyclic path to a goal 
	   explore_acycle(@{$path_ref},$adjacent);
	}      
      }
    } # remove startNode entry to facilitate acyclic path determination
    delete($dflabel_ref->{$startNode});
  }
  pop @{$path_ref};
  return @{$path_ref};
}

### Event handling sub references
my %ACYCLES = ();
my $MAX_EXPORE_LEVEL = 1;  # max depth to search for new acycles
my $NUM_MAIN_PATHS   = 10;    # number of main paths to explore

if ($ARGV[1]) {
  $MAX_EXPORE_LEVEL = $ARGV[1];
}

if ($ARGV[2]) {
  $NUM_MAIN_PATHS = $ARGV[2];
}

my $explore_level = 0;
my $main_path_count = 0;

sub explore_acycle { 
  my @acyclic_path = @_; 
  my $original = join('~>',@acyclic_path);
  #printf("%s\n",join('~>',@acyclic_path)) if ($explore_level == $MAX_EXPORE_LEVEL);

  # return if the limit of main paths hasbeen reached
  if ($explore_level == 0) {
    $main_path_count++;
    return if ($main_path_count > $NUM_MAIN_PATHS);
  }
  # return when explore limit has been reached
  return if ($explore_level == $MAX_EXPORE_LEVEL);
  my $acycle = join(',',@acyclic_path);
  $ACYCLES{$acycle}++; # keep total count
  # return if acycle has already been explored
  return if ($ACYCLES{$acycle} > 1);

  $explore_level++;
  printf("%s%s\n",'-'x($explore_level-1),$original);

  # goal nodes are everything in the parent acyclic path 
  # initialize goals

  my @goals = @acyclic_path;# (); #shift @acyclic_path;
  foreach my $node (@acyclic_path) {
    #push(@goals,$node);
    #printf("start: %s; potential goals: %s\n",$node,join(',',@goals));                          
    my @path           = (); # scoped, stores path
    my %dflabel        = (); # scoped lookup table for dflable
    my $lastDFLabel    =  0;
    sd_path($node,[@goals],[@path],\%dflabel,$lastDFLabel);
  }
  $explore_level--;
}

### Call main
&main;

foreach (keys(%ACYCLES)) {
  #print "$ACYCLES{$_} .... $_";
}

my $c = keys(%ACYCLES);
printf("%s acycles\n",$c);
