#!/usr/bin/env perl

# RegEx LL(1) Parser

$^W++;
use strict;
use Data::Dumper;

#
# Parse table is hard coded (easy way out, but this could be
# created dynamically - including FIRST and FOLLOW - pretty
# easily given a grammar)
#
my %LL_TABLE = (
    R       => {id  => 'O',           '(' => 'O'},
    O       => {id  => 'C O_prime',   '(' => 'C O_prime'},
    O_prime => {'|' => '| C O_prime', ')' => '| C O_prime', '$' => '@'},
    C       => {id  => 'S C_prime',   '(' => 'S C_prime'},
    C_prime => {'|' => '. S C_prime', '.' => '. S C_prime', ')' => '. S C_prime', '$' => '@'},
    S       => {id  => 'L S_prime',   '(' => 'L S_prime'},
    S_prime => {'*' => '* S_prime', ')' => '* S_prime', '$' => '@'},
    L       => {id  => 'id',        '(' => '( R )',     '$' => '@'},
);

# Loop over test data after __DATA__
while () {
    print "################\n$_################\n";
    parse($_);
    print "\n";
}

# print out parse table
print "\n##LL(1) Parse Table##\n";
foreach my $A (keys(%LL_TABLE)) {
    print "$A\n";
    foreach my $alpha (keys(%{$LL_TABLE{$A}})) {
        print "   $alpha  --> $LL_TABLE{$A}{$alpha}\n";
    }
}

# Main parser subroutine
sub parse {
    my $re = shift;
    chomp($re);
    my @STRING = insert_cats(split(//, $re));
    my @STACK = ('$', 'R');

    while (@STRING) {
        my $target = shift(@STRING);
        my $done   = 0;
        my $top    = '';
        while (!$done && defined($top)) {
            print_stack(@STACK);
            $top = pop(@STACK);
            if ($top eq '$') {
                $done++;
            }
            elsif ($top eq 'id' || $top eq '.' || $top eq '*') {
                # print "Match!\n";
                $done++;
            }
            else {    # assuming production @ this point - R, O, etc
                my $replace = get_production($top, $target);
                # print "[$top,$target]\n";
                if (defined($replace)) {
                    push(@STACK, reverse(split(' ', $replace)));
                }
            }
        }
    }
}

# Prings parser stack contents
sub print_stack {
    my @stack = @_;
    foreach (@stack) {
        print "$_ ";
    }
    print "\n";
}

# Inserts cat symbol in appropriate places
sub insert_cats {
    my @string = @_;
    my @new    = ();
    my $prev   = undef;
    my $curr   = undef;
    foreach (@string) {
        $curr = $_;
        if (defined($prev)) {
            if ((is_terminal($curr) && is_terminal($prev))) {
                push(@new, '.', $curr);
            }
            elsif ($prev eq '*' && ($curr ne '*' && $curr ne '|')) {
                push(@new, '.', $curr);
            }
            else {
                push(@new, $curr);
            }
        }
        else {
            push(@new, $curr);
        }
        $prev = $curr;
    }
    #  print Dumper(@new);
    #  exit;
    return @new;
}

# Queries %LL_PARSER table for production rule to use give the
# current non-terminal and target symbol
# A ->  |  | ...
sub get_production {
    my $A      = shift;
    my $target = shift;
    if (is_terminal($target)) {
        $target = 'id';
    }

    my $alpha = $LL_TABLE{$A}{$target};

    if (!defined($alpha) && defined($LL_TABLE{$A}{'$'})) {
        $alpha = '';
    }    # else, return an undefined $alpha

    return $alpha;
}

# Tests if given symbol is a terminal
sub is_terminal {
    return is_member(shift, get_terminals());
}

# Gets all terminal symbols; "@" is epsilon
sub get_terminals {
    my @TERMINALS = ('(', ')', '@');
    push(@TERMINALS, qw(a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9));
    return @TERMINALS;
}

# tests if given value is in given array
sub is_member {
    my $test = shift;
    my $ret  = 0;
    if (defined($test)) {
        foreach (@_) {
            if (defined($_)) {
                if ($test eq $_) {
                    $ret++;
                    last;
                }
            }
        }
    }
    return $ret;
}

# Regexs to test
__DATA__
ad|cb|(d*|)
((ab)*(bc)*)*
(a*|(b*|c*)*)bc*
(a|b|c|d|e|)*
ea*b*c*e*d*e
e|((b||((a|b)|c))|b)
(((c*)**)b)*
(a(b(dc*)*)*)
a***
