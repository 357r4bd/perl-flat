package FLAT::Regex::Util;
use base 'FLAT::Regex';

use strict;
use Carp;

# not the best place to put it, but the best for now I guess...

sub random_pre {
  use FLAT::Regex::WithExtraOps;
  # Percent chance of each operator occuring
  my $LENGTH  = ($_[0] ? $_[0] : 16);
  my $OR      = 6;
  my $STAR    = 30;
  my $OPEN    = 5;
  my $CLOSE   = 0;
  my $AND     = 10;    
  my $getRandomChar = sub {
    my $ch = '';
    # Get a random character between 0 and 127.
    do {
      $ch = int(rand 2);
    } while ($ch !~ m/[a-zA-Z0-9]/);  
    return $ch;
  };
  my $getRandomRE = sub {
    my $str = '';
    my @closeparens = ();
    for (1..$LENGTH) {
      $str .= $getRandomChar->();  
      # % chance of an "or"
      if (int(rand 100) < $OR) {
	$str .= "|1";
      } elsif (int(rand 100) < $AND) {
	$str .= "&0";
      } elsif (int(rand 100) < $STAR) {
	$str .= "*1";     
      } elsif (int(rand 100) < $OPEN) {
	$str .= "(";
	push(@closeparens,'0101)');
      } elsif (int(rand 100) < $CLOSE && @closeparens) {
	$str .= pop(@closeparens);
      }
    }
    # empty out @closeparens if there are still some left
    if (@closeparens) {
      $str .= join('',@closeparens);  
    }
    return FLAT::Regex::WithExtraOps->new($str);
  };
  return $getRandomRE->();  
}

1;
