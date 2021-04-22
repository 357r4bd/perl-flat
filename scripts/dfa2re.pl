#!/usr/bin/env perl -l
use strict;

use lib qw(../lib);
use FLAT::DFA;
use FLAT::Regex::WithExtraOps;

my $dfa;

# get our dfa first
$dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

#now try to derive an equivalent from the DFA

