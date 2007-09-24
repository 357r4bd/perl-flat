#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

{ # closure privatizes $c;
  my %dflabel = ();
  my $lastDFLabel = 0;
  sub get_sub {
    my $start = shift;
    if (!exists($dflabel{$start})) {
      $dflabel{$start} = ++$lastDFLabel;
      my %nodelist = %{get_nodelist()};
      my @ret = ();
      foreach my $adjacent (keys(%{$nodelist{$start}})) {
        my $s = sub { print '-'x$lastDFLabel,"$start -> $adjacent\n"; return get_sub($adjacent); }; 
        push(@ret,$s);
      }
      return @ret;
    }
    return sub { };
  }
 
 sub startover {
   %dflabel = ();
   $lastDFLabel = 0;
 }
}


foreach my $node (keys(%{get_nodelist()})) {
  my @stack = ();
  push(@stack,get_sub($node));

  while (@stack) {
    my $s = pop @stack;
    push(@stack,$s->()); 
  }

  startover();
}

sub get_nodelist {
  return {'6'  => { '9'  => [ 'e' ], '2' => [ 'c' ] },
          '11' => { '8'  => [ 'c' ] },
          '3'  => { '6'  => [ 'd' ], '0' => [ 'c' ] },
          '7'  => { '10' => [ 'f' ], '9' => [ 'b' ] },
          '9'  => { '11' => [ 'f' ], '5' => [ 'c' ] },
          '2'  => { '4'  => [ 'a' ], '5' => [ 'e' ] },
          '8'  => { '10' => [ 'a' ] },
          '4'  => { '6'  => [ 'b' ], '7' => [ 'e' ] },
          '1'  => { '4'  => [ 'd' ], '3' => [ 'b' ] },
          '0'  => { '1'  => [ 'a' ], '2' => [ 'd' ] },
          '10' => { '11' => [ 'b' ] },
          '5'  => { '8'  => [ 'f' ], '7' => [ 'a' ] } };
}
