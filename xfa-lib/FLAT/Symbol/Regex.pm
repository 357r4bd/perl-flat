package FLAT::Symbol::Regex;

use base 'FLAT::Symbol';
use FLAT::Regex;

use strict;

sub new {
  my ($pkg, $label) = @_;
  bless { 
    COUNT  => 1,
    OBJECT => FLAT::Regex->new($label),
    LABEL  => $label,
  }, $pkg;
}

sub as_string {
  my $self = shift;
  return $self->{OBJECT}->as_string;
}

1; 
