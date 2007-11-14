use strict;

use lib qw(../lib);
use FLAT;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $PFA1;
my $PFA2;
my $DFA1;
my $DFA2;

my $NFA1;
$NFA1 = FLAT::Regex::WithExtraOps->new('a*+b*')->as_nfa();
$DFA1 = $NFA1->as_min_dfa ;
