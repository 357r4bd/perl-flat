#!/usr/bin/env perl

use strict;
use warnings;

my @DNA = qw/A C T G/;
my $seq = gen_permutate(14, @DNA);

while ( my $strand = $seq->() ) {
    print "$strand\n";
    sleep 1;
}
sub gen_permutate {
    my ($max, @list) = @_;
    my @curr;
    return sub {
        if ( (join '', map { $list[ $_ ] } @curr) eq $list[ -1 ] x @curr ) {
            @curr = (0) x (@curr + 1);
        }
        else {
            my $pos = @curr;
            while ( --$pos > -1 ) {
                ++$curr[ $pos ], last if $curr[ $pos ] < $#list;
                $curr[ $pos ] = 0;
            }
        }
        return undef if @curr > $max;
        return join '', map { $list[ $_ ] } @curr;
    };
}
