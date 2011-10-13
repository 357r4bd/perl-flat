#!/usr/bin/env perl

#
# RegEx LR(0) Parser
#

$^W++;
use strict;
use Data::Dumper;

#
# RE Grammar
#

my %GRAMMAR = (
  r1  => 'R_prime>R',
  r2  => 'R>O',  
  r3  => 'O>O | C',
  r4  => 'O>C',  
  r5  => 'C>C . S',
  r6  => 'C>S',  
  r7  => 'S>S *', 
  r8  => 'S>L',  
  r9  => 'L>id', 
  r10 => 'L>( R )' 
);

#
# Parse table is hard coded
#

my %LR_TABLE = ( 
  s0  => {id=>'s6',  '|'=>undef, '.'=>undef, '*'=>undef, '('=>'s7',  ')'=>undef, '#'=>undef,    R=>1,     O=>2,     C=>3,     S=>4,     L=>5},
  s1  => {id=>undef, '|'=>undef, '.'=>undef, '*'=>undef, '('=>undef, ')'=>undef, '#'=>'accept', R=>undef, O=>undef, C=>undef, S=>undef, L=>undef},
  s2  => {id=>undef, '|'=>'s8',  '.'=>undef, '*'=>undef, '('=>undef, ')'=>'r2',  '#'=>'r2',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef},
  s3  => {id=>undef, '|'=>'r4',  '.'=>'s9',  '*'=>undef, '('=>undef, ')'=>'r4',  '#'=>'r4',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s4  => {id=>undef, '|'=>'r6',  '.'=>'r6',  '*'=>'s10', '('=>undef, ')'=>'r6',  '#'=>'r6',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef},
  s5  => {id=>undef, '|'=>'r8',  '.'=>'r8',  '*'=>'r8',  '('=>undef, ')'=>'r8',  '#'=>'r8',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef},
  s6  => {id=>undef, '|'=>'r9',  '.'=>'r9',  '*'=>'r9',  '('=>undef, ')'=>'r9',  '#'=>'r9',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s7  => {id=>'s6',  '|'=>undef, '.'=>undef, '*'=>undef, '('=>'s7',  ')'=>undef, '#'=>undef,    R=>11,    O=>2,     C=>3,     S=>4,     L=>5},
  s8  => {id=>'s6',  '|'=>undef, '.'=>undef, '*'=>undef, '('=>'s7',  ')'=>undef, '#'=>undef,    R=>undef, O=>undef, C=>12,    S=>4,     L=>5}, 
  s9  => {id=>'s6',  '|'=>undef, '.'=>undef, '*'=>undef, '('=>'s7',  ')'=>undef, '#'=>undef,    R=>undef, O=>undef, C=>undef, S=>13,    L=>5}, 
  s10 => {id=>undef, '|'=>'r7',  '.'=>'r7',  '*'=>'r7',  '('=>undef, ')'=>'r7',  '#'=>'r7',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s11 => {id=>undef, '|'=>undef, '.'=>undef, '*'=>undef, '('=>undef, ')'=>'s14', '#'=>undef,    R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s12 => {id=>undef, '|'=>'r3',  '.'=>'s9',  '*'=>undef, '('=>undef, ')'=>'r3',  '#'=>'r3',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s13 => {id=>undef, '|'=>'r5',  '.'=>'r5',  '*'=>'s10', '('=>undef, ')'=>'r5',  '#'=>'r5',     R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
  s14 => {id=>undef, '|'=>'r10', '.'=>'r10', '*'=>'r10', '('=>undef, ')'=>'r10', '#'=>'r10',    R=>undef, O=>undef, C=>undef, S=>undef, L=>undef}, 
);

my @INIT_INPUT = ();

# Loop over test data after __DATA__
while () {
  chomp($_);
  print "\n#################\n$_\n";
  parse("$_");
  print "\n";
}

print Dumper(%LR_TABLE);

# Main parser subroutine
sub parse {
  my $re = shift;
  chomp($re);
  my @INPUT_STACK = insert_cats(split(//,$re));
  my @STACK = ('#','s0');
  # initialize first symbol
  my $symbol = '@';
  while ($symbol eq '@') {
    $symbol = shift @INPUT_STACK;
  }
  while (1) {
    my $state = peek(@STACK);
    my $action = action($state,$symbol);
    if (!defined($action)) {
      print "Error!  No entry at M[$state,$symbol]\n";
      print "###DEBUG INFO###\n";
      print "Current input symbol: $symbol\n";
      print "Current state: $state\n";
      print "Stack:\n";
      print_stack(@STACK);
      print "Input Stack:\n";
      print_stack(@INPUT_STACK);
      print "Original Input:\n";
      print_stack(@INIT_INPUT);
      exit;
    } elsif (is_shift($action)) {
      print "shift!  ($action on M[$state,$symbol])\n";
      if (is_id_symbol($symbol)) {
        push(@STACK,'id');
      } else {
        push(@STACK,$symbol);
      }
      print_stack(@STACK);     
      push(@STACK,$action);
      # advance input symbol
      $symbol = shift @INPUT_STACK;
      while ($symbol eq '@') {
	$symbol = shift @INPUT_STACK;
      }      
      print_stack(@STACK);
    } elsif (is_reduce($action)) {
      print "reduce! ($action on M[$state,$symbol])\n";
      _reduce(\@STACK,$action); 
    } elsif (accepted($action)) {
      print "accepted on M[$state,$symbol]\n";
      last;
    } else {
      die "Unspecified error detected!\n";
    }
  }
}

sub _reduce {
  my $STACK_REF = shift;
  my $action = shift;
  my $production = $GRAMMAR{$action};
  my @prod = split('>',$production);
  my @RHS = split(' ',$prod[1]);
  for (-1..($#RHS)*2) {
    pop(@{$STACK_REF});
    print_stack(@{$STACK_REF});    
  }
  my $s = peek(@{$STACK_REF});
  my $top = action($s,$prod[0]);
  if (!defined($top)) {
    die "Error at [$s,$prod[0]]\n"
  }
  $top = "s$top";
  push(@{$STACK_REF},$prod[0]);
  print_stack(@{$STACK_REF});  
  push(@{$STACK_REF},$top);
  print_stack(@{$STACK_REF});
  return;
}

sub is_shift {
  my $test = shift;
  my $ok = 0;
  if (defined($test)) {
    if (defined($LR_TABLE{$test})) {
      $ok++;
    }
  }
  return $ok;
}

sub is_reduce {
  my $test = shift;
  my $ok = 0;
  if (defined($test)) {
    if (defined($GRAMMAR{$test})) {
      $ok++;
    }
  }
  return $ok;

}

sub action {
  my $state = shift;
  my $symbol = shift;
  my $ret = undef;
  if (is_id_symbol($symbol)) {
    $ret = $LR_TABLE{$state}{id};
  } elsif ($symbol eq '@') {
    $ret = $state;
  } else {
    $ret = $LR_TABLE{$state}{$symbol};
  } 
  return $ret;  
}

sub accepted {
  my $action = shift;
  my $ok = 0;
  if ($action eq 'accept') {
    $ok++;
  }
  return $ok;
}

sub peek {
  my @array = @_;
  return $array[$#array];
}

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
  my @new = ();
  my $prev = undef;
  my $curr = undef;
  foreach (@string) {
    $curr = $_;
    if (defined($prev)) {
      if ((is_id_symbol($curr) && is_id_symbol($prev))) { 
        push(@new,'.',$curr);
      } elsif (is_id_symbol($prev) && $curr eq '(') {
        push(@new,'.',$curr);	
      } elsif ($prev eq ')' && is_id_symbol($curr)) {
        push(@new,'.',$curr);
      } elsif ($prev eq '*' && is_id_symbol($curr)) {
      	push(@new,'.',$curr);
      } elsif ($prev eq '*' && $curr eq '(') {
      	push(@new,'.',$curr);
      } else {
        push(@new,$curr);
      }
    } else {
      push(@new,$curr);
    }
    $prev = $curr;
  }
  push(@new,'#');
  @INIT_INPUT = @new;
  print_stack(@new);
  return @new;
}


# Gets all terminal symbols; "@" is epsilon
sub get_id_symbols {
  my @ID_SYMBOLS =qw(a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9);
  return @ID_SYMBOLS;
}

# Tests if given symbol is an id symbol
sub is_id_symbol {
  return is_member(shift,get_id_symbols());
}

# Gets all terminal symbols; "@" is epsilon
sub get_terminals {
  my @TERMINALS = ('(',')','@','.');
  push(@TERMINALS,get_id_symbols());
  return @TERMINALS;
}

# Tests if given symbol is an id symbol
sub is_terminal {
  return is_member(shift,get_terminals());
}

# Gets all terminal symbols; "@" is epsilon
sub get_nonterminals {
  my @NONTERMINALS = ('R_prime','R','O','C','S','L');
  return @NONTERMINALS;
}

# Tests if given symbol is an id symbol
sub is_nonterminal {
  return is_member(shift,get_nonterminals());
}

# tests if given value is in given array
sub is_member {
  my $test = shift;
  my $ret = 0;
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
((ab)*(bc)*)*
ad|cb|(d*)
ea*b*c*e*d*e
(a|b|c|d|e)*
a***
((ab)*(bc)*)*
(a*|(b*|c*)*)bc*
(((c*)**)b)*
(a(b(dc*)*)*)
e|((b|((a|b)|c))|b)
