#!/usr/bin/env perl
use strict;
use warnings;

sub recurse_factory {
  my $max = shift;
  my $number = shift;
  if ($number < $max) {
    return sub { return recurse_factory($max,$number+1); }
  } else {
    return sub { print "done ... $number\n"; };
  }
}

my $TIMES = 100;
my $next = recurse_factory(100,0);
for (1..$TIMES+1) {
  $next = $next->();
}

1;
