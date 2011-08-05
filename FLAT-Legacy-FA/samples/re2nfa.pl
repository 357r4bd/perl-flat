#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# NFA to DFA driver
#
# $Revision: 1.1 $ $Date: 2006/02/23 05:11:01 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use Data::Dumper;
use lib qw(../);
use RE;
use NFA;
use DFA;

if (defined($ARGV[0])) {
  my $test = $ARGV[0];
  chomp($test);
  my $re = RE->new();
  print "$test\n";
  $re->set_re($test);
  my $nfa = $re->to_nfa();
  my $dfa = $nfa->to_dfa();
  print $dfa->info();
  $dfa->number_states();
  print $dfa->info();
  print "Validate strings (ctrl-c to quit)\n";
  while (1) {
    printf("\r>>");
    my $in = <STDIN>;
    chomp($in);
    if ($dfa->is_valid($in)) {
      printf("\rvalid :)\n");
    } else {
      printf("\rnot valid!\n");
    }
  }
} else {
  my @strings = qw(aaa d ccccb dabaabcd cd abcde ccd bc eade ab cdd ddd bc ababb bcbcababbc aabc bcbcccbbc eabccde de);
  push(@strings,'');
  while (<DATA>) {
    my $re = RE->new();
    my $test = $_;
    chomp($test);
    print "$test\n";
    $re->set_re($test);
    my $nfa = $re->to_nfa();
    my $dfa = $nfa->to_dfa();
    $dfa->number_states();
    print $dfa->info();
    my $c = 0;
    foreach (@strings) {
      $c++;
      chomp($_);
      if ($dfa->is_valid($_)) {
	print "\tLine $c: '$_' \n";
      } 
    }
  }
}
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
