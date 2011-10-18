#!/usr/bin/env perl -l

#
# TODO
#  1. from paths, get valid strings
#  2. implement int FLAT and provide interface via fash
#  3. investigate acycles more closely, look at how
#  4. subsequent goal nodes may be manipulated to influence
#     results
#

use strict;
use warnings;
use lib qw(../lib);
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $dfa   = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks();
my %nodes = $dfa->as_node_list();

### Event handling sub references
my %ACYCLES            = ();
my $NUM_MAIN_PATHS     = 5;    # number of main paths to explore
my $MAX_EXPORE_LEVEL   = 1;    # max depth to search for new acycles
my $CONSIDER_BACKEDGES = 0;

$NUM_MAIN_PATHS   = $ARGV[1] if ($ARGV[1]);
$MAX_EXPORE_LEVEL = $ARGV[2] if ($ARGV[2]);
$CONSIDER_BACKEDGES++ if ($ARGV[3]);

my $explore_level   = 0;
my $main_path_count = 0;

#
# Bread and butta function - finds all acyclic paths from given start node to
# a set of goal nodes; all tracking is self contained and no global vars are
# used
#

sub sd_path {
    my $startNode   = shift;
    my $goals_ref   = shift;
    my $path_ref    = shift;
    my $dflabel_ref = shift;
    my $lastDFLabel = shift;
    # add start node to path
    push(@{$path_ref}, $startNode);
    # only continue if startNode has not been visited yet
    if (!exists($dflabel_ref->{$startNode})) {
        $dflabel_ref->{$startNode} = ++$lastDFLabel;    # increment, then assign
        foreach my $adjacent (keys(%{$nodes{$startNode}})) {
            if (!exists($dflabel_ref->{$adjacent})) {    # initial tree edge
                @{$path_ref} = sd_path($adjacent, [@{$goals_ref}], [@{$path_ref}], $dflabel_ref, $lastDFLabel);
                # assumes some base path found
                if ($dfa->array_is_subset([$adjacent], [@{$goals_ref}])) {
                    # handle discovery of an acyclic path to a goal
                    explore_acycle(@{$path_ref}, $adjacent);
                }
            }
            elsif (0 < $CONSIDER_BACKEDGES) {
                # back edge that lands on an accepting node
                if ($dfa->array_is_subset([$adjacent], [@{$goals_ref}])) {
                    # handle discovery of an acyclic path to a goal
                    explore_acycle(@{$path_ref}, $adjacent);
                }
            }
        }    # remove startNode entry to facilitate acyclic path determination
        delete($dflabel_ref->{$startNode});
    }
    pop @{$path_ref};
    return @{$path_ref};
}

# exploration driver uses a sub reference to the function
# that gets the acyclic path...since there are many that it
# could use: get sd_path, shortest path, longest path, etc

my $GET_ACYCLE = \&sd_path;

sub explore_acycle {
    my @acyclic_path = @_;
    my $original = join('~>', @acyclic_path);

### controls
    # return if the limit of main paths has been reached
    if ($explore_level == 0) {
        $main_path_count++;
        return if ($main_path_count > $NUM_MAIN_PATHS);
    }
    # return when explore limit has been reached
    return if ($explore_level > $MAX_EXPORE_LEVEL);
    my $acycle = join(',', @acyclic_path);
    $ACYCLES{$acycle}++;    # keep total count
                            # return if acycle has already been explored
    return if ($ACYCLES{$acycle} > 1);
### controls

    $explore_level++;
    printf("%s%s\n", '-' x ($explore_level - 1), $original);

    # goal nodes are everything in the parent acyclic path
    # initialize goals

    ##goal management options:
    # 1. all nodes in A all the time
    # 2. only self and df(node) =< df(self)  # back edges
    # 3. only self and df(node) > df(self)   # fwd edges

    my @goals = ();    #shift @acyclic_path;
    foreach my $node (@acyclic_path) {
        push(@goals, $node);
        #printf("start: %s; potential goals: %s\n",$node,join(',',@goals));
        my @path        = ();    # scoped, stores path
        my %dflabel     = ();    # scoped lookup table for dflable
        my $lastDFLabel = 0;
        $GET_ACYCLE->($node, [@goals], [@path], \%dflabel, $lastDFLabel);
    }
    $explore_level--;
}

### Subroutines
sub main {
    my @path        = ();        # scoped, stores path
    my %dflabel     = ();        # scoped lookup table for dflable
    my $lastDFLabel = 0;
    # accepts start node and set of possible goals
    $GET_ACYCLE->($dfa->get_starting(), [$dfa->get_accepting()], [@path], \%dflabel, $lastDFLabel);
    foreach (keys(%ACYCLES)) {
        #print "$ACYCLES{$_} .... $_";
    }
    my $c = keys(%ACYCLES);
    printf("%s acycles\n", $c);
}

### Call main
&main;

