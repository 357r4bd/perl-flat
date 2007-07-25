#!/usr/bin/env perl -l
use strict;

use lib qw(../lib);
use FLAT::DFA;
use FLAT::Regex::WithExtraOps;

# perl bdetest.pl "a&b&c&d" will give you all permutations ... once the transformations are done.
# because it takes so darn long to do transformations, it it might be useful to have a native
# interface to dumping a "frozen" DFA object to file...time to investigate 

print STDERR <<END;

  This example includes the serialization of the DFA object, 
  so if the file exists, it will not go through the transformation again;
  In a basic sense, this is an example of compressing data - compare the 
  size of the serialized object with a text file containing all strings stored
  in the DFA.  The "compression" is even more extreme if you compare the size 
  of the output'd text with the size of the actual regular expression.
END

my $dfa;
#example:
use Storable;

mkdir "dat" if (! -e "dat");

if (!-e "dat/$ARGV[0].dat") {
  $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
  store $dfa, "dat/$ARGV[0].dat";
} else {
  print STDERR "dat/$ARGV[0].dat found.."; 
  $dfa = retrieve "dat/$ARGV[0].dat";
}

my %nodes = $dfa->as_node_list();

my %dflabel       = ();    # "global" lookup table for dflable
my %backtracked   = (); # "global" lookup table for backtracked edges
my %low           = (); # "global" lookup table for low
my $lastDFLabel   = 0;
my $recurse_level = 0; # tracks recurse level
my @string        = ();
# anonymous, recursive function

&acyclic($dfa->get_starting());

# this function finds all acyclic paths in the dfa for each symbol!!
sub acyclic {                            
  my $startNode = shift;
  $recurse_level++; # <- tracker
# tree edge detection
  if (!exists($dflabel{$startNode})) {
    $dflabel{$startNode} = ++$lastDFLabel;  # the order inwhich this link was explored
    $low{$startNode} = $lastDFLabel;
    $backtracked{$startNode} = 0;           # marks this node as visited before - for cross edge detection
    foreach my $adjacent (keys(%{$nodes{$startNode}})) {
      if (!exists($dflabel{$adjacent})) {      # initial tree edge
        foreach my $symbol (@{$nodes{$startNode}{$adjacent}}) {
	  push(@string,$symbol);
          acyclic($adjacent);
          $backtracked{$adjacent}++;  # <- track backtracked nodes
	  if ($low{$startNode} > $low{$adjacent}) {
	    $low{$startNode} = $low{$adjacent};
	  }	
	  if ($dfa->is_accepting($adjacent)) {
            printf("%s\n",join('',@string));
	  }
	  pop(@string);
        }
      }
    } 
  }
  # remove startNode entry to facilitate acyclic path determination
  delete($dflabel{$startNode});
  $lastDFLabel--;
  $recurse_level--; # <- tracker
  return;     
};
