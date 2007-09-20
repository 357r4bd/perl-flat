#!/usr/bin/env perl
use strict;
use warnings;

sub recurse {
  my $max = shift;
  my $number = shift;
  if ($number < $max) {
    return sub { return recurse($max,$number+1); }
  } else {
    return sub { print "done\n"; };
  }
}

my $next = recurse(3,0);
$next = $next->();
$next = $next->();
$next = $next->();
$next = $next->();

1;
