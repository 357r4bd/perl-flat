#
# Conceptual Experiment - not currently implemented anywhere...
#

package FLAT::Symbol

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

1;

##################

package FLAT::Symbol::Regular;
use base 'FLAT::Symbol';

sub new {
  my $pkg = shift;
  my $self = $pkg->SUPER::new($_[0],'Regular');
  return $self;
}

sub get_type {
  return 'Regular';
}

sub set_type {
  croak("Sorry, can't change type for this symbol");
}

1; 

##################

package FLAT::Symbol::Special;
use base 'FLAT::Symbol';

sub new {
  my $pkg = shift;
  my $self = $pkg->SUPER::new($_[0],'Special');
  return $self;
}

sub get_type {
  return 'Special';
}

sub set_type {
  croak("Sorry, can't change type for this symbol");}

1;

__END__

=head1 NAME

FLAT::Symbol - Base class for transition symbol

=head1 SYNOPSIS

A super class that is intended to provide a simple mechanism for storing a symbol that might be 
in conflict with another symbol in string form.  TYPE is used to distinguish.  Currenly this neither 
this, nor its current sub classes, Regular and Special, are used.
