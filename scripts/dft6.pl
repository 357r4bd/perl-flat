#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(../lib);
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;
use Data::Dumper;
use Storable qw(dclone);

my $dfa      = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
my $MAXLEVEL = 1;

sub get_sub {
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
                            return get_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref, $lastDFLabel,
                                $max);
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
        string      => ($dfa->array_is_subset([$start], [@{$accepting_ref}]) ? join('', @{$string_ref}) : undef)
    };
}

sub init {
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $dfa->as_node_list();
    my %dflabel     = ();
    my %backtracked = ();                     # tracks nodes from which we've backtracked for cross edge detection
    my %taintpoints = ();                     # tracks taint points
    my %kgroups     = ();                     # strong components + nodes reachable via them
    my %crossedges  = ();                     # tracks cross edges to check
    foreach my $node (keys(%nodelist)) {
        $dflabel{$node} = [];                 # initializes anonymous arrays for all nodes
    }
    my @accepting = $dfa->get_accepting();
    # initialize
    my @substack = ();
    my $r = get_sub($dfa->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel, $MAXLEVEL);
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

my $iter = init();
while (my $x = $iter->()) {
    print "$x\n";
}

1;
