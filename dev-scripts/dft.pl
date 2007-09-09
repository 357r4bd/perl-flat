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

# define path finding subs

my @path_list           = ();
my @backedge_list       = ();
my @accepting_backedges = ();

### Event handling sub references
my $onAcyclic     = sub { #push(@path_list,[@_]);                   
                          print join('->',@_);
                        };
my $onAccBackedge = sub { #push(@accepting_backedges,[@_]); 
                          print join('~>',@_);
                        };

### Subroutines
sub main {
  my @path           = (); # scoped, stores path
  my %dflabel        = (); # scoped lookup table for dflable
  my $lastDFLabel    =  0;
  # accepts start node and set of possible goals
  sd_path($dfa->get_starting(),[$dfa->get_accepting()],[@path],\%dflabel,$lastDFLabel); 
}

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
    $dflabel_ref->{$startNode} = ++$lastDFLabel;
    foreach my $adjacent (keys(%{$nodes{$startNode}})) {
      if (!exists($dflabel_ref->{$adjacent})) {   # initial tree edge
	@{$path_ref} = sd_path($adjacent,[@{$goals_ref}],[@{$path_ref}],$dflabel_ref,$lastDFLabel);
	# assumes some base path found
        if ($dfa->array_is_subset([$adjacent],[@{$goals_ref}])) {   
           # handle discovery of an acyclic path to a goal 
	   $onAcyclic->(@{$path_ref},$adjacent);
	} # back edge detection... 
      } else {
        # does backedge destination also accept?
        if ($dfa->array_is_subset([$adjacent],[@{$goals_ref}])) {
          # handle the discovery of an accepting backedge
 	  $onAccBackedge->(@{$path_ref},$adjacent); # yes
        }
      }
    } # remove startNode entry to facilitate acyclic path determination
    delete($dflabel_ref->{$startNode});
  }
  pop @{$path_ref};
  return @{$path_ref};
}

sub explode {

}

sub path_to_string {

}

### Call main
&main;

__END__
