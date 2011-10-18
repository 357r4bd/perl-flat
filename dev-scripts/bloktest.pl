#!/usr/bin/perl

use lib '../lib';
use FLAT::NFA;
use FLAT::Regex;
use Data::Dumper;

# my $regex = FLAT::Regex->new("abc*+[]c(d+e)");
# printf "$regex becomes %s\n", $regex->as_perl_regex;

sub foo {
    FLAT::Regex->new(shift)->as_min_dfa;
}

my $dfa1 = foo("((a+b)(a+b))*");
my $dfa2 = foo("a*");

my $result = $dfa1->intersect($dfa2);

print $result->as_gdl;
