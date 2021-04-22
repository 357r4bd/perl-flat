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

my $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

sub get_acyclic_sub {
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
                        return get_acyclic_sub($adjacent, $nodelist_ref, $dflabel_clone, $string_clone, $accepting_ref,
                            $lastDFLabel);
                    }
                );
                pop @{$string_ref};
            }
        }
    }
    return {
        substack    => [@ret],
        lastDFLabel => $lastDFLabel,
        string      => ($dfa->array_is_subset([$start], [@{$accepting_ref}]) ? join('', @{$string_ref}) : undef)
    };
}

sub init_acyclic_iterator {
    my %dflabel     = ();
    my @string      = ();
    my $lastDFLabel = 0;
    my %nodelist    = $dfa->as_node_list();
    my @accepting   = $dfa->get_accepting();

    # initialize
    my @substack = ();
    my $r = get_acyclic_sub($dfa->get_starting(), \%nodelist, \%dflabel, \@string, \@accepting, $lastDFLabel);
    push(@substack, @{$r->{substack}});

    #...need explicit init/reset funcs..

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

my $iter = init_acyclic_iterator();
while (my $x = $iter->()) {
    print "$x\n";
}

1;
