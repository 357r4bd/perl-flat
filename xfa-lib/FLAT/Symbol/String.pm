package FLAT::Symbol::Char;
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
