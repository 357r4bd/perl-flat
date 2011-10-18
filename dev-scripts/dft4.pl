#!/usr/bin/env perl
use strict;
use warnings;

{
    my %seen;
    my %tree = (
        A => ['B', 'C'],
        B => ['D', 'E'],
        C => ['F', 'G'],
        E => ['H', 'I'],
        G => ['J', 'K'],
        H => ['L', 'M', 'N'],
        I => ['O', 'P'],
        K => ['Q'],
    );

    sub get_root {'A'}

    sub get_children {
        my ($node) = @_;
        return $tree{$node} ? @{$tree{$node}} : ();
    }

    sub visited {
        my ($node, $val) = @_;
        return $seen{$node} = $val if defined $val;
        return $seen{$node};
    }
}

sub gen_tree_iter {
    my @nodes = get_root();
    return sub {
        {
            my $node = shift @nodes;
            return undef if !defined $node;
            redo if visited($node);
            visited($node => 1);
            unshift @nodes, get_children($node);
            return $node;
        }
    };
}

my $iter = gen_tree_iter();

while (my $node = $iter->()) {
    print "Visiting $node\n";
}
