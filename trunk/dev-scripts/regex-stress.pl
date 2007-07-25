#!/usr/bin/env perl -l
use strict;

use lib qw(../lib);
use FLAT;
use FLAT::Regex;
use FLAT::NFA;
use FLAT::DFA;
use Getopt::Long;  # used to process commandline options
$|++;

# skirt around deep recursion warning annoyance
local $SIG{__WARN__} = sub { $_[0] =~ /^Deep recursion/ or warn $_[0] };
srand $$;

my %CMDLINEOPTS = ();
# Percent chance of each operator occuring
$CMDLINEOPTS{LENGTH} = 5;
$CMDLINEOPTS{OR} = 6;
$CMDLINEOPTS{STAR} = 10;
$CMDLINEOPTS{OPEN} = 5;
$CMDLINEOPTS{CLOSE} = 0;
$CMDLINEOPTS{n} = 100;

 GetOptions("l=s"        => \$CMDLINEOPTS{LENGTH},
 	    "n=s"        => \$CMDLINEOPTS{n},
	    "or=s"       => \$CMDLINEOPTS{OR},
            "star=s"     => \$CMDLINEOPTS{STAR},
	    "open=s"     => \$CMDLINEOPTS{OPEN},
	    "close=s"    => \$CMDLINEOPTS{CLOSE},
	    );
 
sub getRandomChar {
  my $ch = '';
  # Get a random character between 0 and 127.
  do {
    $ch = int(rand 2);
  } while ($ch !~ m/[a-zA-Z0-9]/);  
  return $ch;
}

sub getRandomRE {
  my $str = '';
  my @closeparens = ();
  for (1..$CMDLINEOPTS{LENGTH}) {
    $str .= getRandomChar();  
    # % chance of an "or"
    if (int(rand 100) < $CMDLINEOPTS{OR}) {
      $str .= "|[]";
    } elsif (int(rand 100) < $CMDLINEOPTS{STAR}) {
      $str .= "*";    
    } elsif (int(rand 100) < $CMDLINEOPTS{OPEN}) {
      $str .= "(";
      push(@closeparens,'[])');
    } elsif (int(rand 100) < $CMDLINEOPTS{CLOSE} && @closeparens) {
      $str .= pop(@closeparens);
    }
  }
  # empty out @closeparens if there are still some left
  if (@closeparens) {
    $str .= join('',@closeparens);  
  }
  return $str;
}

for (1..$CMDLINEOPTS{n}) {
  my $str = getRandomRE();  
  my $RE = FLAT::Regex->new($str);
  print $RE->as_regex();
  print $RE->as_nfa()->as_dfa()->as_min_dfa()->as_summary();
}
