#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use lib qw(../lib);
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my $dfa = FLAT::Regex::WithExtraOps->new($ARGV[0])->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;

sub get_sub {
  my $start = shift;
  my $nodelist_ref = shift;
  my $dflabel_ref  = shift;
  my $lastDFLabel  = shift;
  my @ret = ();
  foreach my $adjacent (keys(%{$nodelist_ref->{$start}})) {
    if (!exists($dflabel_ref->{$adjacent})) {
      $dflabel_ref->{$adjacent} = ++$lastDFLabel;
      push(@ret,sub { print '-'x$dflabel_ref->{$adjacent},"$start .. $adjacent\n"; 
                      return get_sub($adjacent,$nodelist_ref,+{%{$dflabel_ref}},$lastDFLabel);}); 
    }
  }
  return @ret;
}
  
my %dflabel = ();
my $lastDFLabel = 0;
my %nodelist = $dfa->as_node_list();

# initialize
my @stack = ();
# preload @stack
push(@stack,get_sub($dfa->get_starting(),\%nodelist,\%dflabel,$lastDFLabel));

while (@stack) {
  my $s = pop @stack;
  push(@stack,$s->()); 
}

1;
