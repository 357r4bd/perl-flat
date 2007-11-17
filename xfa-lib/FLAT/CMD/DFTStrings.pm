# all strings available via depth first traversal, including back edges that happen to land on an accepting state

package FLAT::CMD::DFTStrings;
use base 'FLAT::CMD';
use FLAT;
use FLAT::Regex::WithExtraOps;
use FLAT::PFA;
use FLAT::XFA;
use FLAT::DFA;
use Storable;
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
    # caches results, loads them in if detexted
    my $RE = FLAT::Regex::WithExtraOps->new($PRE);
    printf("%s\n",$RE->as_string());
    if (!-e "$PRE.dat") {
      $dfa = $RE->as_pfa->as_xfa->as_dfa->as_min_dfa->trim_sinks;
      #store $dfa, "$PRE.dat";
    } else {
      print STDERR "$PRE.dat found..";
      $dfa = retrieve "$PRE.dat";
    }

    $dfa->as_dft_strings(shift);
}

1;