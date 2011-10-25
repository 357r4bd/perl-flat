package FLAT::DFA::Util;

use strict;
use warnings;
use parent 'FLAT::DFA';

# Need to implement! http://www.ianab.com/hyper/
# DFA hyper-minimization using equivalence classes
sub as_hyper_min_dfa {
    my $self = shift()->clone;
}

# DFT stuff in preparation for DFA pump stuff;
sub as_node_list {
    my $self = shift;
    my %node = ();
    for my $s1 ($self->get_states) {
        $node{$s1} = {};    # initialize
        for my $s2 ($self->get_states) {
            my $t = $self->get_transition($s1, $s2);
            if (defined $t) {
                # array of symbols that $s1 will go to $s2 on...
                push(@{$node{$s1}{$s2}}, split(',', $t->as_string));
            }
        }
    }
    return %node;
}

sub as_acyclic_strings {
    my $self        = shift;
    my %dflabel     = ();                      # lookup table for dflable
    my %backtracked = ();                      # lookup table for backtracked edges
    my $lastDFLabel = 0;
    my @string      = ();
    my %nodes       = $self->as_node_list();
    # output format is the actual PRE followed by all found strings
    $self->acyclic($self->get_starting(), \%dflabel, $lastDFLabel, \%nodes, \@string);
}

sub acyclic {
    my $self        = shift;
    my $startNode   = shift;
    my $dflabel_ref = shift;
    my $lastDFLabel = shift;
    my $nodes       = shift;
    my $string      = shift;
    # tree edge detection
    if (!exists($dflabel_ref->{$startNode})) {
        $dflabel_ref->{$startNode} = ++$lastDFLabel;    # the order inwhich this link was explored
        foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
            if (!exists($dflabel_ref->{$adjacent})) {    # initial tree edge
                foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
                    push(@{$string}, $symbol);
                    $self->acyclic($adjacent, \%{$dflabel_ref}, $lastDFLabel, \%{$nodes}, \@{$string});
                    if ($self->array_is_subset([$adjacent], [$self->get_accepting()])) {    #< proof of concept
                        printf("%s\n", join('', @{$string}));
                    }
                    pop(@{$string});
                }
            }
        }
    }
    # remove startNode entry to facilitate acyclic path determination
    delete($dflabel_ref->{$startNode});
    #$lastDFLabel--;
    return;
}

sub as_dft_strings {
    my $self  = shift;
    my $depth = 1;
    $depth = shift if (1 < $_[0]);
    my %dflabel = ();                      # scoped lookup table for dflable
    my %nodes   = $self->as_node_list();
    foreach (keys(%nodes)) {
        $dflabel{$_} = [];                 # initialize container (array) for multiple dflables for each node
    }
    my $lastDFLabel = 0;
    my @string      = ();
    $self->dft($self->get_starting(), [$self->get_accepting()], \%dflabel, $lastDFLabel, \%nodes, \@string, $depth);
}

sub dft {
    my $self        = shift;
    my $startNode   = shift;
    my $goals_ref   = shift;
    my $dflabel_ref = shift;
    my $lastDFLabel = shift;
    my $nodes       = shift;
    my $string      = shift;
    my $DEPTH       = shift;
    # add start node to path
    my $c1 = @{$dflabel_ref->{$startNode}};    # get number of elements
    if ($DEPTH >= $c1) {
        push(@{$dflabel_ref->{$startNode}}, ++$lastDFLabel);
        foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
            my $c2 = @{$dflabel_ref->{$adjacent}};
            if ($DEPTH > $c2) {                # "initial" tree edge
                foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
                    push(@{$string}, $symbol);
                    $self->dft($adjacent, [@{$goals_ref}], $dflabel_ref, $lastDFLabel, $nodes, [@{$string}], $DEPTH);
                    # assumes some base path found
                    if ($self->array_is_subset([$adjacent], [@{$goals_ref}])) {
                        printf("%s\n", join('', @{$string}));
                    }
                    pop(@{$string});
                }
            }
        }    # remove startNode entry to facilitate acyclic path determination
        pop(@{$dflabel_ref->{$startNode}});
        $lastDFLabel--;
    }
}

#
# String gen using iterators (still experimental)
#

sub get_acyclic_sub {
    my $self = shift;
    my ($start, $nodelist_ref, $dflabel_ref, $string_ref, $accepting_ref, $lastDFLabel) = @_;
    my @ret = ();
    foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
        $lastDFLabel++;
        if (!exists($dflabel_ref->{$adjacent})) {
            $dflabel_ref->{$adjacent} = $lastDFLabel;
            foreach my $symbol (@{$nodelist_ref->{$start}{$adjacent}}) {
                push(@{$string_ref}, $symbol);
                my $string_clone  = dclone($string_ref);
                my $dflabel_clone = dclone($dflabel_ref);
                push(
                    @ret,
                    sub {
                        return $self->get_acyclic_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref,
                            $lastDFLabel);
                    }
                );
                pop @{$string_ref};
            }
        }

    }
    # returns a complex data structure in the form of a hash reference
    return {
        substack    => [@ret],
        lastDFLabel => $lastDFLabel,
        string      => ($self->array_is_subset([$start], [@{$accepting_ref}]) ? join('', @{$string_ref}) : undef)
    };
}

sub init_acyclic_iterator {
    my $self        = shift;
    my %dflabel     = ();
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $self->as_node_list();
    my @accepting   = $self->get_accepting();
    # initialize
    my @substack = ();
    my $r = $self->get_acyclic_sub($self->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel);
    push(@substack, @{$r->{substack}});
    return sub {
        while (1) {
            if (!@substack) {
                return undef;
            }
            my $s = pop @substack;
            my $r = $s->();
            push(@substack, @{$r->{substack}});
            if ($r->{string}) {
                return $r->{string};
            }
        }
        }
}

sub new_acyclic_string_generator {
    my $self = shift;
    return $self->init_acyclic_iterator();
}

sub get_deepdft_sub {
    my $self = shift;
    my ($start, $nodelist_ref, $dflabel_ref, $string_ref, $accepting_ref, $lastDFLabel, $max) = @_;
    my @ret = ();
    my $c1  = @{$dflabel_ref->{$start}};
    if ($c1 < $max) {
        push(@{$dflabel_ref->{$start}}, ++$lastDFLabel);
        foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
            my $c2 = @{$dflabel_ref->{$adjacent}};
            if ($c2 < $max) {
                foreach my $symbol (@{$nodelist_ref->{$start}{$adjacent}}) {
                    push(@{$string_ref}, $symbol);
                    my $string_clone  = dclone($string_ref);
                    my $dflabel_clone = dclone($dflabel_ref);
                    push(
                        @ret,
                        sub {
                            return $self->get_deepdft_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref,
                                $lastDFLabel, $max);
                        }
                    );
                    pop @{$string_ref};
                }
            }
        }
    }
    return {
        substack    => [@ret],
        lastDFLabel => $lastDFLabel,
        string      => ($self->array_is_subset([$start], [@{$accepting_ref}]) ? join('', @{$string_ref}) : undef)
    };
}

sub init_deepdft_iterator {
    my $self        = shift;
    my $MAXLEVEL    = shift;
    my %dflabel     = ();
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $self->as_node_list();
    foreach my $node (keys(%nodelist)) {
        $dflabel{$node} = [];    # initializes anonymous arrays for all nodes
    }
    my @accepting = $self->get_accepting();
    # initialize
    my @substack = ();
    my $r = $self->get_deepdft_sub($self->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel, $MAXLEVEL);
    push(@substack, @{$r->{substack}});
    return sub {
        while (1) {
            if (!@substack) {
                return undef;
            }
            my $s = pop @substack;
            my $r = $s->();
            push(@substack, @{$r->{substack}});
            if ($r->{string}) {
                return $r->{string};
            }
        }
        }
}

sub new_deepdft_string_generator {
    my $self = shift;
    my $MAXLEVEL = (@_ ? shift : 1);
    return $self->init_deepdft_iterator($MAXLEVEL);
}

1;

__END__

=head1 NAME

FLAT::DFA::Util - Utility functions for Deterministic finite automata

=head1 SYNOPSIS

A FLAT::DFA object is a finite automata whose transitions are labeled
with single characters. Furthermore, each state has exactly one outgoing
transition for each available label/character. 

=head1 USAGE

In addition to implementing the interface specified in L<FLAT> and L<FLAT::NFA>, 
FLAT::DFA::Util objects provide the following DFA-specific methods:

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

=item $dfa-E<gt>as_node_list

This method returns a node list in the form of a hash. This node list may be viewed as a 
pure digraph, and is lacking in state names and transition symbols.

=item $dfa-E<gt>as_acyclic_strings

The method is B<deprecated>, and it is suggested that one not use it.  It returns all 
valid strings accepted by the DFA by exploring all acyclic paths that go from the start
state and end in an accepting state.  The issue with this method is that it finds and
returns all strings at once.  The iterator described below is much more ideal for actual
use in an application.

=item $dfa-E<gt>as_dft_strings($depth)

The method is B<deprecated>, and it is suggested that one not use it.  It returns all 
valid strings accepted by the DFA using a depth first traversal.  A valid string is formed
when the traversal detects an accepting state, whether it is a terminal node or a node reached
via a back edge.  The issue with this method is that it finds and returns all strings at once.  
The iterator described below is much more ideal for actual use in an application.

The argument, C<$depth> specifies how many times the traversal may actually pass through
a previously visited node.  It is therefore possible to safely explore DFAs that accept
infinite languages.

=item $dfa-E<gt>new_acyclic_string_generator

This allows one to initialize an iterator that returns a valid string on each successive
call of the sub-ref that is returned. It returns all valid strings accepted by the DFA by 
exploring all acyclic paths that go from the start state and end in an accepting state.

Example:

 #!/usr/bin/env perl
 use strict; 
 use FLAT::DFA;
 use FLAT::NFA;
 use FLAT::PFA;
 use FLAT::Regex::WithExtraOps; 

 my $PRE = "abc&(def)*";
 my $dfa = FLAT::Regex::WithExtraOps->new($PRE)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks; 
 my $next = $dfa->new_acyclic_string_generator; 
 print "PRE: $PRE\n";
 print "Acyclic:\n";
 while (my $string = $next->()) {
   print "  $string\n";
 }

=item $dfa-E<gt>new_deepdft_string_generator($depth)

This allows one to initialize an iterator that returns a valid string on each successive
call of the sub-ref that is returned. It returns all valid strings accepted by the DFA using a 
depth first traversal.  A valid string is formed when the traversal detects an accepting state, 
whether it is a terminal node or a node reached via a back edge.

The argument, C<$depth> specifies how many times the traversal may actually pass through
a previously visited node.  It is therefore possible to safely explore DFAs that accept
infinite languages.

 #!/usr/bin/env perl
 use strict; 
 use FLAT::DFA;
 use FLAT::NFA;
 use FLAT::PFA;
 use FLAT::Regex::WithExtraOps; 

 my $PRE = "abc&(def)*";
 my $dfa = FLAT::Regex::WithExtraOps->new($PRE)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks; 
 my $next = $dfa->new_deepdft_string_generator();
 print "Deep DFT (default):\n";
 for (1..10) {
  while (my $string = $next->()) {
    print "  $string\n";
    last;
   }
 }

 $next = $dfa->new_deepdft_string_generator(5);
 print "Deep DFT (5):\n";
 for (1..10) {
   while (my $string = $next->()) {
     print "  $string\n";
     last;
   }
 }

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
