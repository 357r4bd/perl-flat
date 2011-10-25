package FLAT::DFA;

use strict;
use warnings;
use parent 'FLAT::NFA';
use FLAT::DFA::Util;
use Storable qw(dclone);
use Carp;
$|++;

sub set_starting {
    my $self = shift;
    $self->SUPER::set_starting(@_);

    my $num = () = $self->get_starting;
    confess "DFA must have exactly one starting state"
        if $num != 1;
}

sub complement {
    my $self = $_[0]->clone;

    for my $s ($self->get_states) {
        $self->is_accepting($s)
            ? $self->unset_accepting($s)
            : $self->set_accepting($s);
    }

    return $self;
}

sub _TUPLE_ID {join "\0", @_}

sub _uniq {
    my %seen;
    grep {!$seen{$_}++} @_;
}

## this method still needs more work..
sub intersect {
    my @dfas = map {$_->as_dfa} @_;

    my $return = FLAT::DFA->new;
    my %newstates;
    my @alpha = _uniq(map {$_->alphabet} @dfas);

    $_->_extend_alphabet(@alpha) for @dfas;

    my @start = map {$_->get_starting} @dfas;
    my $start = $newstates{_TUPLE_ID(@start)} = $return->add_states(1);
    $return->set_starting($start);
    $return->set_accepting($start)
        if !grep {!$dfas[$_]->is_accepting($start[$_])} 0 .. $#dfas;

    my @queue = (\@start);
    while (@queue) {
        my @tuple = @{shift @queue};

        for my $char (@alpha) {
            my @next = map {$dfas[$_]->successors($tuple[$_], $char)} 0 .. $#dfas;

            #warn "[@tuple] --> [@next] via $char\n";

            if (not exists $newstates{_TUPLE_ID(@next)}) {
                my $s = $newstates{_TUPLE_ID(@next)} = $return->add_states(1);
                $return->set_accepting($s)
                    if !grep {!$dfas[$_]->is_accepting($next[$_])} 0 .. $#dfas;
                push @queue, \@next;
            }

            $return->add_transition($newstates{_TUPLE_ID(@tuple)}, $newstates{_TUPLE_ID(@next)}, $char);
        }
    }

    return $return;
}

# this is meant to enforce 1 starting state for a DFA, but it is getting us into trouble
# when a DFA object calls unset_starting
sub unset_starting {
    my $self = shift;
    $self->SUPER::unset_starting(@_);
    my $num = () = $self->unset_starting;
    croak "DFA must have exactly one starting state"
        if $num != 1;
}

#### transformations

sub trim_sinks {
    my $self   = shift;
    my $result = $self->clone();
    foreach my $state ($self->array_complement([$self->get_states()], [$self->get_accepting()])) {
        my @ret = $self->successors($state, [$self->alphabet]);
        if (@ret) {
            if ($ret[0] == $state) {
                $result->delete_states($state) if ($result->is_state($state));
            }
        }
    }
    return $result;
}

# classical DFA minimization using equivalence classes
sub as_min_dfa {
    my $self     = shift()->clone;
    my $N        = $self->num_states;
    my @alphabet = $self->alphabet;
    my ($start)  = $self->get_starting;
    my %final    = map {$_ => 1} $self->get_accepting;
    my @equiv    = map [(0) x ($_ + 1), (1) x ($N - $_ - 1)], 0 .. $N - 1;
    while (1) {
        my $changed = 0;
        for my $s1 (0 .. $N - 1) {
            for my $s2 (grep {$equiv[$s1][$_]} 0 .. $N - 1) {
                if (1 == grep defined, @final{$s1, $s2}) {
                    $changed = 1;
                    $equiv[$s1][$s2] = 0;
                    next;
                }
                for my $char (@alphabet) {
                    my @t = sort {$a <=> $b} $self->successors([$s1, $s2], $char);
                    next if @t == 1;

                    if (not $equiv[$t[0]][$t[1]]) {
                        $changed = 1;
                        $equiv[$s1][$s2] = 0;
                    }
                }
            }
        }
        last if !$changed;
    }
    my $result = (ref $self)->new;
    my %newstate;
    my @classes;
    for my $s (0 .. $N - 1) {
        next if exists $newstate{$s};

        my @c = ($s, grep {$equiv[$s][$_]} 0 .. $N - 1);
        push @classes, \@c;

        @newstate{@c} = ($result->add_states(1)) x @c;
    }
    for my $c (@classes) {
        my $s = $c->[0];
        for my $char (@alphabet) {
            my ($next) = $self->successors($s, $char);
            $result->add_transition($newstate{$s}, $newstate{$next}, $char);
        }
    }
    $result->set_starting($newstate{$start});
    $result->set_accepting($newstate{$_}) for $self->get_accepting;
    $result;
}

# the validity of a given string <-- executes symbols over DFA
# if there is not transition for given state and symbol, it fails immediately
# if the current state we're in is not final when symbols are exhausted, then it fails

sub is_valid_string {
    my $self   = shift;
    my $string = shift;
    chomp $string;
    my $OK = undef;
    my @stack = split('', $string);
    # this is confusing all funcs return arrays
    my @current = $self->get_starting();
    my $current = pop @current;
    foreach (@stack) {
        my @next = $self->successors($current, $_);
        if (!@next) {
            return $OK;    #<--returns undef bc no transition found
        }
        $current = $next[0];
    }
    $OK++ if ($self->is_accepting($current));
    return $OK;
}

1;

__END__

=head1 NAME

FLAT::DFA - Deterministic finite automata

=head1 SYNOPSIS

A FLAT::DFA object is a finite automata whose transitions are labeled
with single characters. Furthermore, each state has exactly one outgoing
transition for each available label/character. 

=head1 USAGE

In addition to implementing the interface specified in L<FLAT> and L<FLAT::NFA>, 
FLAT::DFA objects provide the following DFA-specific methods:

=over

=item $dfa-E<gt>unset_starting

Because a DFA, by definition, must have only ONE starting state, this allows one to unset
the current start state so that a new one may be set.

=item $dfa-E<gt>trim_sinks

This method returns a FLAT::DFA (though in theory an NFA) that is lacking a transition for 
all symbols from all states.  This method eliminates all transitions from all states that lead
to a sink state; it also eliminates the sink state.

This has no affect on testing if a string is valid using C<FLAT::DFA::is_valid_string>, 
discussed below.

=item $dfa-E<gt>as_min_dfa

This method minimizes the number of states and transitions in the given DFA. The modifies
the current/calling DFA object.

=item $dfa-E<gt>is_valid_string($string)

This method tests if the given string is accepted by the DFA.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
