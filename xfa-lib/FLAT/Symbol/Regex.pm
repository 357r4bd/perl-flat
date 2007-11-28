package FLAT::Symbol::Regex;

use base 'FLAT::Symbol';
use FLAT::Regex::WithExtraOps;

use strict;

sub new {
  my ($pkg, $label) = @_;
  bless { 
    COUNT  => 1,
    OBJECT => $label !~ m/^\s*$/g ? FLAT::Regex::WithExtraOps->new($label) : FLAT::Regex::WithExtraOps->new('[epsilon]'),
    LABEL  => $label,
  }, $pkg;
}

sub as_string {
  my $self = shift;
  return $self->{OBJECT}->as_string;
}

# provided interface to merging labels

sub union {
  my $self = shift;
  $self->{OBJECT}->union($_[0]->{OBJECT});
  # update label
  $self->{LABEL} = $self->{OBJECT}->as_string;
}

1; 
