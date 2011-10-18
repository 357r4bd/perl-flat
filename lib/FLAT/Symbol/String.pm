package FLAT::Symbol::String;

use base 'FLAT::Symbol';

use strict;

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new($_[0]);
    return $self;
}

1;
