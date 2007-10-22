use Test::More 'no_plan';

use strict;

#use lib qw(../lib);
use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

# w&w
my $PFA1 = FLAT::Regex::WithExtraOps->new('abc&def')->as_pfa();
my $PFA2 = FLAT::Regex::WithExtraOps->new('a(b(c&def)+d(ef&bc))+d(ef&abc)')->as_pfa();
my $DFA1 = $PFA1->as_nfa->as_min_dfa;
my $DFA2 = $PFA2->as_nfa->as_min_dfa;

is( ($DFA1->equals($DFA2)), 1 );

# w&w*
# w&v*
$PFA1 = FLAT::Regex::WithExtraOps->new('abc&(def)*')->as_pfa();
$PFA2 = FLAT::Regex::WithExtraOps->new('(def)*( a(bc&(def)*)+
                                              d((efd)*ef&(abc))+
                                              d((efd)*&(abc))ef)')->as_pfa();

$DFA1 = $PFA1->as_nfa->as_min_dfa;
$DFA2 = $PFA2->as_nfa->as_min_dfa;

is( ($DFA1->equals($DFA2)), 1);

# w*&v*
# throws some weird warning from FA.pm when mimimizing, but passes still
$PFA1 = FLAT::Regex::WithExtraOps->new('(abc)*&(def)*')->as_pfa();
$PFA2 = FLAT::Regex::WithExtraOps->new('((abc+def)*( a((bca)*bc&(def)*)+
                                                    a((bca)*&(def)*)bc+
                                                    d((efd)*ef&(abc)*)+
                                                    d((efd)*&(abc)*)ef
                                                    )*)*')->as_pfa();

__END__ #<-- uncomment for more intensive and time consuming tests

$DFA1 = $PFA1->as_nfa->as_min_dfa;
$DFA2 = $PFA2->as_nfa->as_min_dfa;
 is( ($DFA1->equals($DFA2)), 1);

# w*x&v*y
$PFA1 = FLAT::Regex::WithExtraOps->new('(abc)*dx&(efg)*hy')->as_pfa(); 
$PFA2 = FLAT::Regex::WithExtraOps->new('(abc+efg)*( dx&(efg)*hy+
                                                  hy&(abc)*dx+
                                                  a(((bca)*bcdx)&((efg)*hy))+
                                                  a(((bca)*)&((efg)*hy))bcdx+
                                                  e(((fge)*fghy)&((abc)*dx))+
                                                  e(((fge)*)&((abc)*dx))fghy
                                                  )')->as_pfa();

$DFA1 = $PFA1->as_nfa->as_min_dfa;
$DFA2 = $PFA2->as_nfa->as_min_dfa;
is( ($DFA1->equals($DFA2)), 1);

$PFA1 = FLAT::Regex::WithExtraOps->new('nop(abc)*hij&qrs(def)*klm')->as_pfa();
$PFA2 = FLAT::Regex::WithExtraOps->new('n(op(abc)*hij&qrs(def)*klm)+q(rs(def)*klm&nop(abc)*hij)')->as_pfa();

$DFA1 = $PFA1->as_nfa->as_min_dfa;
$DFA2 = $PFA2->as_nfa->as_min_dfa;
is( ($DFA1->equals($DFA2)), 1);
