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
my %dflabel        = (); # scoped lookup table for dflable
my $lastDFLabel    =  0;
my @path           = (); # scoped, stores path
my $exploreLevel   =  0; # only truly global variable - tracks how many levels deep we explore
use constant MAX_EXPLORE_LEVEL => 2;

# define path finding subs

my @path_list           = ();
my @backedge_list       = ();
my @accepting_backedges = ();

### Event handling sub references
my $onAcyclic     = sub { push(@path_list,[@_]); # if (@path_list <= 5);                   
                          # just get first 5
                        };
my $onBackedge    = sub { push(@backedge_list,[@_]); #  if (@backedge_list <= 5);         
                          # just get first 5
                        };
my $onAccBackedge = sub { push(@accepting_backedges,[@_]); 
                          # if (@accepting_backedges <= 5); # just get first 5
                        };

### Subroutines
sub main {
  # accepts start node and set of possible goals
  sd_path($dfa->get_starting(),[$dfa->get_accepting()],[@path]); 

  printf("Found %s Acyclic Base Paths\n",($#path_list+1));
  printf("Found %s Non-accepting Backedge Paths\n",($#accepting_backedges+1));
  printf("Found %s Accepting Backedge Paths\n",($#backedge_list+1));

}

sub sd_path {
  my $startNode = shift;
  my $goals_ref = shift;
  my $path_ref  = shift;
  # add start node to path
  push (@{$path_ref},$startNode);
  # only continue if startNode has not been visited yet
  if (!exists($dflabel{$startNode})) {
    $dflabel{$startNode} = ++$lastDFLabel;
    foreach my $adjacent (keys(%{$nodes{$startNode}})) {
      if (!exists($dflabel{$adjacent})) {   # initial tree edge
	@{$path_ref} = sd_path($adjacent,[@{$goals_ref}],[@{$path_ref}]);
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
        } else {
          # handle the discovery of a non-accepting backedge
 	  $onBackedge->(@{$path_ref},$adjacent); # no
	}
      }
    } # remove startNode entry to facilitate acyclic path determination
    delete($dflabel{$startNode});
    $lastDFLabel--;
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

           if ( $exploreLevel <= MAX_EXPLORE_LEVEL) {
	     $exploreLevel++;

	     my @base_path = @{$path_ref};
  	     foreach my $branch (reverse @base_path) {
  	       printf("%s\n",join('->',@base_path));
	       #print "$branch";
	       my $branch = pop @base_path;

	       # signifies the beginning of a new sd acyclic path search, so scope in a new dflabel and lastDFLabel
	       my %dflabel     = (); # scoped lookup table for dflable
	       my $lastDFLabel =  0; # scoped tracker for last dflabel
               my @path        = (); # scoped and stores lastest path
	     
               @path = sd_path($branch,[@base_path],[@path]);   
               printf("%s\n",join('.>',@path)) if (@path);
             }
	     
             $exploreLevel--;
          }
