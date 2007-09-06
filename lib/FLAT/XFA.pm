package FLAT::XFA;
use strict;
use base 'FLAT::DFA';
use Carp;
$|++;

# an XFA is an FA (implemented as a DFA here) that allows for RE's 
# as transition symbols; this causes us to track a "type" of state
# that determines if a transition to itself indicates a closure or 
# not

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_); # <-- SUPER is FLAT::DFA
    return $self;
}

# elimiates states based on my "elimination algorithm," which
# may ver well be what HSU had in mind, but I couldn't under
# stand their description

sub eliminate_states {
    my $self = shift;
} 

# applies XFS->eliminate_states such that the start state
# is the only one that remains

sub as_re {
    my $self = shift;
  
}

1;
