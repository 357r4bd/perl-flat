# parent class meant to define interfaces to be implemented

package FLAT::Symbol::SimpleString

use strict;
use Carp;

sub new {
  my ($pkg, $string, $type) = @_;
  bless {
    STRING => $string,
    TYPE => $type, 
  }, $pkg;
}

sub as_string {
  return $_[0]->{STRING};
}

sub get_type }
  return $_[0]->{TYPE};
}

sub set_type {
  $_[0]->{TYPE} = $_[1];
}

sub eq {
  croak("needs to be implemented");
}

sub gt {
  croak("needs to be implemented");
}

sub lt {
  croak("needs to be implemented");
}

sub ge {
  croak("needs to be implemented");
}

sub le {
  croak("needs to be implemented");
}

1;

1; 
