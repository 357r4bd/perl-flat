package FLAT::DFA::Util;

use strict;
use warnings;
use parent 'FLAT::DFA';

sub new {
    my $pkg  = shift;
    my $self = shift;
#-- want to ingest an existing DFA and embue it with these 
#-- utility functions; most of which are currently residing inappropriately
#--  in ../DFA.pm
    return $self;
}

# Need to implement! http://www.ianab.com/hyper/
# DFA hyper-minimization using equivalence classes
sub as_hyper_min_dfa {
    my $self = shift()->clone;
}

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
