package FLAT::XFA;
use strict;
use base 'FLAT::DFA';
use Carp;
$|++;

=head1 NAME

FLAT::XFA - X Finite Automata

=head1 SYNOPSIS

An XFA is a FA (implemented as a DFA here) that allows for RE's as transition symbols; this
will be used, for among other things, the implementation of the conversion, DFA to RE, using
state elimination.

=head1 USAGE

none; not yet implemented.

=cut

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

__END__

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
