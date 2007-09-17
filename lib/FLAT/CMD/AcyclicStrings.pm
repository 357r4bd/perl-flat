# all strings available via acyclic path from the DFA start state to any all of the final states

package FLAT::CMD::AcyclicStrings;
use base 'FLAT::CMD';
use FLAT;
use FLAT::Regex;
use FLAT::NFA;
use FLAT::DFA;
use Carp;

# Support for perl one liners - like what CPAN.pm uses #<- should move all to another file
use base 'Exporter'; #instead of: use Exporter (); @ISA = 'Exporter';
use vars qw(@EXPORT $AUTOLOAD);

@EXPORT = qw(as_strings);

sub AUTOLOAD {
    my($l) = $AUTOLOAD;
    $l =~ s/.*:://;
    my(%EXPORT);
    @EXPORT{@EXPORT} = '';
    if (exists $EXPORT{$l}){
	FLAT::CMD->$l(@_);
    }
}

use vars qw(%nodes %dflabel %backtracked %low $lastDFLabel @string $dfa);
# acyclic - no cycles
sub as_strings {
    my $PRE = shift;
    # neat a better way to get input via stdin
    if (!$PRE) {
      while (<>) {
        chomp;
        $PRE = $_;
        last;
      }
    } 
    use FLAT::Regex::WithExtraOps;
    use FLAT::PFA;
    use FLAT::NFA;
    use FLAT::DFA;
    use Storable;
    # caches results, loads them in if detexted
    my $RE = FLAT::Regex::WithExtraOps->new($PRE);
    if (!-e "$PRE.dat") {
      $dfa = $RE->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
      #store $dfa, "$PRE.dat";
    } else {
      #print STDERR "$PRE.dat found..";
      $dfa = retrieve "$PRE.dat";
    }

    my %dflabel       = (); # lookup table for dflable
    my %backtracked   = (); # lookup table for backtracked edges
    my $lastDFLabel   = 0;
    my @string        = ();
    my %nodes         = $dfa->as_node_list();
    # output format is the actual PRE followed by all found strings
    print $RE->as_string(),"\n";
    acyclic($dfa->get_starting(),\%dflabel,$lastDFLabel,\%nodes,\@string);
}
sub acyclic {
  my $startNode = shift;
  my $dflabel_ref = shift;
  my $lastDFLabel = shift;
  my $nodes = shift;
  my $string = shift;
  # tree edge detection
  if (!exists($dflabel_ref->{$startNode})) {
    $dflabel_ref->{$startNode} = ++$lastDFLabel;  # the order inwhich this link was explored
    foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
      if (!exists($dflabel_ref->{$adjacent})) {      # initial tree edge
        foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
	  push(@{$string},$symbol);
          acyclic($adjacent,\%{$dflabel_ref},$lastDFLabel,\%{$nodes},\@{$string});
	  if ($dfa->array_is_subset([$adjacent],[$dfa->get_accepting()])) { #< proof of concept
            printf("%s\n",join('',@{$string}));
	  }
	  pop(@{$string});
        }
      }
    } 
  }
  # remove startNode entry to facilitate acyclic path determination
  delete($dflabel_ref->{$startNode});
  #$lastDFLabel--;
  return;     
};
