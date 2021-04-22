#!/bin/env perl

use strict;
use Tie::Hash::Indexed;

sub tieH {
    tie my %hash, 'Tie::Hash::Indexed', @_;
    return \%hash;
}

tie my %test, 'Tie::Hash::Indexed';

%test = (
    1 => tieH(
        a => 100,
        b => 200,
        c => 300
    ),
    2 => tieH(
        d => 400,
        e => 500,
        f => 600
    ),
    3 => tieH(
        g => 700,
        h => 800,
        i => 900
    ),
);

foreach my $key (keys(%test)) {
    print "$key\n";
    foreach my $ikey (keys(%{$test{$key}})) {
        print "  $ikey\n";
    }
}

1;
