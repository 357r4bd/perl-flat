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
use Data::Dumper;

my $RE = FLAT::Regex::WithExtraOps->new($ARGV[0]);
my $dfa;

### Caching Mechanism
### Cache PRE's to disk so that they don't have to be recompiled
use Storable;
mkdir "dat" if (! -e "dat");
if (!-e "dat/$ARGV[0].dat") {
  $dfa = $RE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
  store $dfa, "dat/$ARGV[0].dat";
} else {
  print STDERR "dat/$ARGV[0].dat found.."; 
  $dfa = retrieve "dat/$ARGV[0].dat";
}
### End Cache Mechanism

# define path finding subs

my @path_list           = ();
my @backedge_list       = ();
my @accepting_backedges = ();

### Event handling sub references
my $onAcyclic     = sub { #push(@path_list,[@_]);                   
                          #print join('->',@_);
                          #print_strings(@_);
                        };
my $onAccBackedge = sub { #push(@accepting_backedges,[@_]); 
                          #print join('~>',@_);
                          #print_strings(@_);
                        };

my %nodes = $dfa->as_node_list();

### Subroutines
sub main {
  my @path           = (); # scoped, stores path
  my %dflabel        = (); # scoped lookup table for dflable
  foreach (keys(%nodes)) {
    $dflabel{$_} = []; # initialize container (array) for multiple dflables for each node
  }
  my $lastDFLabel    =  0;
  my @string         = ();
  # accepts start node and set of possible goals
  print $ARGV[0];
  sd_path($dfa->get_starting(),[$dfa->get_accepting()],\%dflabel,$lastDFLabel,\@string); 
}

sub sd_path {
  my $startNode    = shift;
  my $goals_ref    = shift;
  my $dflabel_ref  = shift;
  my $lastDFLabel  = shift;
  my $string       = shift;
  # add start node to path
  my $c1 = @{$dflabel_ref->{$startNode}}; # get number of elements
  if (1 >= $c1) {  
    push(@{$dflabel_ref->{$startNode}},++$lastDFLabel);
    foreach my $adjacent (keys(%{$nodes{$startNode}})) {
      my $c2 = @{$dflabel_ref->{$adjacent}};
      if (2 > $c2) {   # "initial" tree edge
        foreach my $symbol (@{$nodes{$startNode}{$adjacent}}) {
	  push(@{$string},$symbol);
	  sd_path($adjacent,[@{$goals_ref}],$dflabel_ref,$lastDFLabel,[@{$string}]);
	  # assumes some base path found
          if ($dfa->array_is_subset([$adjacent],[@{$goals_ref}])) { 
            printf("%s\n",join('',@{$string}));    
  	  } 
          pop(@{$string}); 
        } 
      }
    } # remove startNode entry to facilitate acyclic path determination
    pop(@{$dflabel_ref->{$startNode}});
    $lastDFLabel--;  # still required ?
  }
}

### Call main
&main;

__END__
