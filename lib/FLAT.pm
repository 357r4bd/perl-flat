package FLAT;
use FLAT::Regex;
use FLAT::NFA;
use FLAT::DFA;
use Carp;

use vars '$VERSION';
$VERSION = 0.01;

## let subclasses implement a minimal set of closure properties.
## they can override these with more efficient versions if they like.

sub as_dfa {
    $_[0]->as_nfa->as_dfa;
}

sub as_min_dfa {
    $_[0]->as_dfa->as_min_dfa;
}

sub is_infinite {
    ! $_[0]->is_finite;
}

sub star {
    $_[0]->kleene
}

sub difference {
    $_[0]->intersect( $_[1]->complement );
}

sub symdiff {
    my $self = shift;
    return $self if not @_;
    my $next = shift()->symdiff(@_);
    ( $self->difference($next) )->union( $next->difference($self) );
}

sub equals {
    $_[0]->symdiff($_[1])->is_empty
}

sub is_subset_of {
    $_[0]->difference($_[1])->is_empty
}


BEGIN {
    for my $method (qw[ as_nfa as_regex union intersect complement concat
                        kleene reverse is_empty is_finite ])
    {
        no strict 'refs';
        *$method = sub {
            my $pkg = ref $_[0] || $_[0];
            carp "$pkg does not (yet) implement $method";
        };
    }
}

# Support for perl one liners - like what CPAN.pm uses #<- should move all to another file
use base 'Exporter'; #instead of: use Exporter (); @ISA = 'Exporter';
use vars qw(@EXPORT $AUTOLOAD);

@EXPORT = qw(compare 
             dump  
	     dfa2gv 
	     nfa2gv 
	     pfa2gv 
	     dfa2digraph
	     nfa2digraph
	     pfa2digraph
	     dfa2undirected
	     nfa2undirected
	     pfa2undirected
	     random_pre 
	     random_re
	     test
	     help
	     );

# Todo: validate, test (string against re), validate (re), 
#       alternate (give re, list some alternates), getstrings (gen strings give re)	     

sub AUTOLOAD {
    my($l) = $AUTOLOAD;
    $l =~ s/.*:://;
    my(%EXPORT);
    @EXPORT{@EXPORT} = '';
    if (exists $EXPORT{$l}){
	FLAT::OneLiners->$l(@_);
    }
}

package FLAT::OneLiners;

sub help {
print <<END
__________             .__    ___________.____         ___________
\______   \ ___________|  |   \_   _____/|    |   _____\__    ___/
 |     ___// __ \_  __ \  |    |    __)  |    |   \__  \ |    |   
 |    |   \  ___/|  | \/  |__  |     \   |    |___ / __ \|    |   
 |____|    \___  >__|  |____/  \___  /   |_______ (____  /____|   
               \/                  \/            \/    \/    
	       
  NB: Everything is wrt parallel regular expressions, i.e., 
  NB: with the addtional shuffle operator, "&".  All this 
  NB: means is that you can use the ambersand (&) as a symbol
  NB: in the regular expressions you submit because it will be 
  NB: detected as an operator.That said, if you avoid using
  NB: the "&" operator, you can forget about all that shuffle
  NB: business.

COMMANDS: 
%perl -MFLAT -e
    "compare  're1','re2'"   # comares 2 regexs | see note [2] 
    "dump     're1'"         # dumps parse trees | see note[1]	   
    "dfa2gv  're1'"          # dumps graphviz graph desc | see note[1]  
    "nfa2gv  're1'"          # dumps graphviz graph desc | see note[1]  
    "pfa2gv  're1'"          # dumps graphviz graph desc | see note[1]  
    dfa2digraph              # dumps directed graph without transitions
    nfa2digraph              # dumps directed graph without transitions
    pfa2digraph              # dumps directed graph without transitions
    dfa2undirected           # dumps undirected graph without transitions
    nfa2undirected           # dumps undirected graph without transitions
    pfa2undirected           # dumps undirected graph without transitions
    random_pre 
    random_re
    "test 'regex' 'string1'" # give a regex, reports if subsequent strings are valid
    help

NOTES:
[1] This means you could presumably do something like the following:
    %perl -MFLAT -e command < text_file_with_1_regex_per_line.txt
                    ^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
[2] This command compares the minimal DFAs of each regular expression;
    if there exists a exact 1-1 mapping of symbols, states, and 
    transitions then the DFAs are considered equal.  This means that 
    "abc" will be equal to "def"  To make matters more confusing, "ab+ac" 
    would be equivalent to "xy+xz"; or worse yet, "z(x+y)". So to the 
    'compare' command, "ab+ac" == "xy+xz" == "z(x+y)". This however 
    does not translate into the situation where "ab+ac" will accept 
    the same LITERAL strings as "z(x+y)" because the symbols are obviously
    different.  Once we implement the "test" command, used to test strings 
    against a regular expression, a concrete example will be provided.   		    
		   
TO DO:
1   Implement "getstrings 're1' [opts...]" # given regex, pump strings 
    based on options
   
2   Implement "variations 're1' [opts...]" # given regex will provide 
    equivalents

3   Allow random_pre and random_re to accept the number of regexes, the
    number of characters, and the character set;  eventually it might be 
    useful to allow modification of the chances of the different operators
    occuring...

CREDITS:
Blockhead, CPAN.pm (for the example of how to implement these one liners), 
and #perl on irc.freenode.net for pointing out something I missed when 
trying to copy CPAN's majik.

Perl FLAT and all included modules are released under the same terms as Perl
itself.  Cheers.

SEE:
http://perl-flat.sourceforge.net

END
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2directed('a&b&c&d*e*')"
sub test {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  use FLAT::NFA;
  use FLAT::DFA;
  # handles multiple strings; first is considered the regex
  if (@_) 
  { my $FA = FLAT::Regex::WithExtraOps->new(shift @_)->as_pfa()->as_nfa->as_dfa(); 
    foreach (@_)
    { if ($FA->is_valid_string($_)) {
        print "(+): $_\n";
      } else {
        print "(-): $_\n";
      }     
    } 
  } else {
    my $FA;
    while (<STDIN>) {
      chomp;
      if ($. == 1) { #<-- uses first line as regex!
        $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa->as_dfa();
      } else {
	if ($FA->is_valid_string($_)) {
	  print "(+): $_\n";
        } else {
	  print "(-): $_\n";
	}      
      }
    }
  }
}

# dumps parse tree
# Usage:
# perl -MFLAT -e "dump('re1','re2',...,'reN')"
# perl -MFLAT -e dump < list_of_regexes.dat
sub dump {
  shift;
  use FLAT::Regex::WithExtraOps;
  use Data::Dumper;
  if (@_) 
  { foreach (@_)
    { my $PRE = FLAT::Regex::WithExtraOps->new($_);
      print Dumper($PRE); }} 
  else    
  { while (<STDIN>) 
     { chomp;
       my $PRE = FLAT::Regex::WithExtraOps->new($_);
       print Dumper($PRE); }
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "dfa2gv('a&b&c&d*e*')"
sub dfa2gv {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa()->as_min_dfa()->trim_sinks();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa()->trim_sinks();
       print $FA->as_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "nfa2gv('a&b&c&d*e*')"
sub nfa2gv {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "pfa2gv('a&b&c&d*e*')"
sub pfa2gv {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_graphviz;} 
  }
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "dfa2directed('a&b&c&d*e*')"
sub dfa2digraph {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  # trims sink states from min-dfa since transitions are gone 
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "nfa2directed('a&b&c&d*e*')"
sub nfa2digraph {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2directed('a&b&c&d*e*')"
sub pfa2digraph {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "dfa2undirected('a&b&c&d*e*')"
sub dfa2undirected {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  # trims sink states from min-dfa since transitions are gone 
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "nfa2undirected('a&b&c&d*e*')"
sub nfa2undirected {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2undirected('a&b&c&d*e*')"
sub pfa2undirected {
  shift;  
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# compares 2 give PREs
# Usage:
# perl -MFLAT -e "compare('a','a&b&c&d*e*')" #<-- no match, btw
sub compare {
  shift;
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::PFA;
  my $PFA1 = FLAT::Regex::WithExtraOps->new(shift)->as_pfa();
  my $PFA2 = FLAT::Regex::WithExtraOps->new(shift)->as_pfa();
  my $DFA1 = $PFA1->as_nfa->as_min_dfa;
  my $DFA2 = $PFA2->as_nfa->as_min_dfa;
  if ($DFA1->equals($DFA2)) {
    print "Yes\n";
  } else {
    print "No\n";
  }
}

# prints random PRE
# Usage:
# perl -MFLAT -e random_pre
sub random_pre {
  shift;
  my $and_chance = shift;
  # skirt around deep recursion warning annoyance
  local $SIG{__WARN__} = sub { $_[0] =~ /^Deep recursion/ or warn $_[0] };
  srand $$;
  my %CMDLINEOPTS = ();
  # Percent chance of each operator occuring
  $CMDLINEOPTS{LENGTH} = 32;
  $CMDLINEOPTS{OR} = 6;
  $CMDLINEOPTS{STAR} = 10;
  $CMDLINEOPTS{OPEN} = 5;
  $CMDLINEOPTS{CLOSE} = 0;
  $CMDLINEOPTS{n} = 1;
  $CMDLINEOPTS{AND} = 10; #<-- default    
  $CMDLINEOPTS{AND} = $and_chance if ($and_chance == 0); #<-- to make it just an re (no shuffle)
  

  my $getRandomChar = sub {
    my $ch = '';
    # Get a random character between 0 and 127.
    do {
      $ch = int(rand 2);
    } while ($ch !~ m/[a-zA-Z0-9]/);  
    return $ch;
  };

  my $getRandomRE = sub {
    my $str = '';
    my @closeparens = ();
    for (1..$CMDLINEOPTS{LENGTH}) {
      $str .= $getRandomChar->();  
      # % chance of an "or"
      if (int(rand 100) < $CMDLINEOPTS{OR}) {
	$str .= "|1";
      } elsif (int(rand 100) < $CMDLINEOPTS{AND}) {
	$str .= "&0";
      } elsif (int(rand 100) < $CMDLINEOPTS{STAR}) {
	$str .= "*1";     
      } elsif (int(rand 100) < $CMDLINEOPTS{OPEN}) {
	$str .= "(";
	push(@closeparens,'0101)');
      } elsif (int(rand 100) < $CMDLINEOPTS{CLOSE} && @closeparens) {
	$str .= pop(@closeparens);
      }
    }
    # empty out @closeparens if there are still some left
    if (@closeparens) {
      $str .= join('',@closeparens);  
    }
    return $str;
  };

  for (1..$CMDLINEOPTS{n}) {
    print $getRandomRE->(),"\n";  
  } 
}

# prints random RE (no & operator)
# Usage:
# perl -MFLAT -e random_re
sub random_re {
  shift->random_pre(0);
}

1;

__END__

=head1 NAME

FLAT - Formal Language & Automata Toolkit

=head1 SYNOPSIS

FLAT.pm is the base class of all regular language objects. For more
information, see other POD pages.

=head1 USAGE

All regular language objects in FLAT implement the following methods.
Specific regular language representations (regex, NFA, DFA) may implement
additional methods that are outlined in the repsective POD pages.

=head2 Conversions Among Representations

=over

=item $lang-E<gt>as_nfa

=item $lang-E<gt>as_dfa

=item $lang-E<gt>as_min_dfa

=item $lang-E<gt>as_regex

Returns an equivalent regular language to $lang in the desired
representation. Does not modify $lang (even if $lang is already in the
desired representation).

For more information on the specific algorithms used in these conversions,
see the POD pages for a specific representation.

=back

=head2 Closure Properties

=over

=item $lang1-E<gt>union($lang2, $lang3, ... )

=item $lang1-E<gt>intersect($lang2, $lang3, ... )

=item $lang1-E<gt>concat($lang2, $lang3, ... )

=item $lang1-E<gt>symdiff($lang2, $lang3, ... )

Returns a regular language object that is the union, intersection,
concatenation, or symmetric difference of $lang1 ... $langN, respectively.
The return value will have the same representation (regex, NFA, or DFA) 
as $lang1.

=item $lang1-E<gt>difference($lang2)

Returns a regular language object that is the set difference of $lang1 and
$lang2. Equivalent to

  $lang1->intersect($lang2->complement)

The return value will have the same representation (regex, NFA, or DFA) 
as $lang1.

=item $lang-E<gt>kleene

=item $lang-E<gt>star

Returns a regular language object for the Kleene star of $lang. The return
value will have the same representation (regex, NFA, or DFA) as $lang.

=item $lang-E<gt>complement

Returns a regular language object for the complement of $lang. The return
value will have the same representation (regex, NFA, or DFA) as $lang.

=item $lang-E<gt>reverse

Returns a regular language object for the stringwise reversal of $lang.
The return value will have the same representation (regex, NFA, or DFA)
as $lang.

=back

=head2 Decision Properties

=over

=item $lang-E<gt>is_finite

=item $lang-E<gt>is_infinite

Returns a boolean value indicating whether $lang represents a
finite/infinite language.

=item $lang-E<gt>is_empty

Returns a boolean value indicating whether $lang represents the empty
language.

=item $lang1-E<gt>equals($lang2)

Returns a boolean value indicating whether $lang1 and $lang2 are
representations of the same language.

=item $lang1-E<gt>is_subset_of($lang2)

Returns a boolean value indicating whether $lang1 is a subset of
$lang2.

=item $lang-E<gt>contains($string)

Returns a boolean value indicating whether $string is in the language
represented by $lang.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and Brett
Estrade E<lt>estradb at mailcan dot comE<gt>.

Initial version by Brett Estrade was work towards an MS thesis at the
University of Southern Mississippi.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
