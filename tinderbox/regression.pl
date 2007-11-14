use strict;

use lib qw(../lib);
use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::Regex;

my $NFA1;
my $DFA1;

# never failed
$NFA1 = FLAT::Regex->new('a*b+c')->as_nfa();
$DFA1 = $NFA1->as_dfa ;

# used to failed
$NFA1 = FLAT::Regex->new('a*')->as_nfa();
$DFA1 = $NFA1->as_dfa ;

# used to failed
$NFA1 = FLAT::Regex->new('a*+c')->as_nfa();
$DFA1 = $NFA1->as_dfa ;

# used to failed
$NFA1 = FLAT::Regex->new('a*+c*')->as_nfa();
$DFA1 = $NFA1->as_dfa ;
