package FLAT::DFA;
use strict;
use base 'FLAT::NFA';
use Carp;
$|++;

sub set_starting {
    my $self = shift;
    $self->SUPER::set_starting(@_);
    
    my $num = () = $self->get_starting;
    confess "DFA must have exactly one starting state"
        if $num != 1;
}

sub complement {
    my $self = $_[0]->clone;
    
    for my $s ($self->get_states) {
        $self->is_accepting($s)
            ? $self->unset_accepting($s)
            : $self->set_accepting($s);
    }
    
    return $self;
}

sub _TUPLE_ID { join "\0", @_ }
sub _uniq { my %seen; grep { !$seen{$_}++ } @_; }

## this method still needs more work..
sub intersect {
    my @dfas = map { $_->as_dfa } @_;
    
    my $return = FLAT::DFA->new;
    my %newstates;
    my @alpha = _uniq( map { $_->alphabet } @dfas );
    
    $_->_extend_alphabet(@alpha) for @dfas;

    my @start = map { $_->get_starting } @dfas;
    my $start = $newstates{ _TUPLE_ID(@start) } = $return->add_states(1);
    $return->set_starting($start);
    $return->set_accepting($start)
        if ! grep { ! $dfas[$_]->is_accepting( $start[$_] ) } 0 .. $#dfas;

    my @queue = (\@start);
    while (@queue) {
        my @tuple = @{ shift @queue };

        for my $char (@alpha) {
            my @next = map { $dfas[$_]->successors( $tuple[$_], $char ) }
                        0 .. $#dfas;
            
            #warn "[@tuple] --> [@next] via $char\n";
            
            if (not exists $newstates{ _TUPLE_ID(@next) }) {
                my $s = $newstates{ _TUPLE_ID(@next) } = $return->add_states(1);
                $return->set_accepting($s)
                    if ! grep { ! $dfas[$_]->is_accepting( $next[$_] ) } 0 .. $#dfas;
                push @queue, \@next;
            }
            
            $return->add_transition( $newstates{ _TUPLE_ID(@tuple) },
                                     $newstates{ _TUPLE_ID(@next) },
                                     $char );
        }            
    }

    return $return;    
}

# this is meant to enforce 1 starting state for a DFA, but it is getting us into trouble
# when a DFA object calls unset_starting
sub unset_starting {
    my $self = shift;    
    $self->SUPER::unset_starting(@_);    
    my $num = () = $self->unset_starting;
    croak "DFA must have exactly one starting state"
        if $num != 1;
}

#### transformations

sub trim_sinks {
  my $self = shift;
  my $result = $self->clone();
  foreach my $state ($self->array_complement([$self->get_states()],[$self->get_accepting()])) {
    my @ret = $self->successors($state,[$self->alphabet]);
    if (@ret) {
      if ($ret[0] == $state) {
        $result->delete_states($state);    
      }
    }
  }
  return $result;
}

sub as_min_dfa {
    my $self     = shift()->clone;
    my $N        = $self->num_states;
    my @alphabet = $self->alphabet;

    my ($start)  = $self->get_starting;
    my %final    = map { $_ => 1 } $self->get_accepting;

    my @equiv = map [ (0) x ($_+1), (1) x ($N-$_-1) ], 0 .. $N-1;

    while (1) {
        my $changed = 0;
        for my $s1 (0 .. $N-1) {
        for my $s2 (grep { $equiv[$s1][$_] } 0 .. $N-1) {
            
            if ( 1 == grep defined, @final{$s1, $s2} ) {
                $changed = 1;
                $equiv[$s1][$s2] = 0;
                next;
            }
            
            for my $char (@alphabet) {
                my @t = sort { $a <=> $b } $self->successors([$s1,$s2], $char);
                next if @t == 1;
                
                if (not $equiv[ $t[0] ][ $t[1] ]) {
                    $changed = 1;
                    $equiv[$s1][$s2] = 0;
                }
            }
        }}
        
        last if !$changed;
    }
    
    my $result = (ref $self)->new;
    my %newstate;
    my @classes;
    for my $s (0 .. $N-1) {
        next if exists $newstate{$s};
        
        my @c = ( $s, grep { $equiv[$s][$_] } 0 .. $N-1 );
        push @classes, \@c;

        @newstate{@c} = ( $result->add_states(1) ) x @c;
    }

    for my $c (@classes) {
        my $s = $c->[0];
        for my $char (@alphabet) {
            my ($next) = $self->successors($s, $char);
            $result->add_transition( $newstate{$s}, $newstate{$next}, $char );
        }
    }
    
    $result->set_starting( $newstate{$start} );
    $result->set_accepting( $newstate{$_} )
        for $self->get_accepting;
    
    $result;

}

# the validity of a given string <-- executes symbols over DFA
# if there is not transition for given state and symbol, it fails immediately
# if the current state we're in is not final when symbols are exhausted, then it fails

sub is_valid_string {
  my $self = shift;
  my $string = shift;
  chomp $string;
  my $OK = undef;
  my @stack = split('',$string);
  # this is confusing all funcs return arrays
  my @current = $self->get_starting();
  my $current = pop @current;
  foreach (@stack) {
    my @next = $self->successors($current,$_);    
    if (!@next) {
      return $OK; #<--returns undef bc no transition found
    }
    $current = $next[0];
  }
  $OK++ if ($self->is_accepting($current));
  return $OK;
}

#
# Experimental!!
#

# DFT stuff in preparation for DFA pump stuff;
sub as_node_list {
    my $self = shift;
    my %node = ();
    for my $s1 ($self->get_states) {
      $node{$s1} = {}; # initialize
      for my $s2 ($self->get_states) {
         my $t = $self->get_transition($s1, $s2);
         if (defined $t) {
           # array of symbols that $s1 will go to $s2 on...
	   push(@{$node{$s1}{$s2}},split(',',$t->as_string)); 
         }
      }
    }
  return %node;
}

sub as_acyclic_strings {
    my $self = shift;
    my %dflabel       = (); # lookup table for dflable
    my %backtracked   = (); # lookup table for backtracked edges
    my $lastDFLabel   = 0;
    my @string        = ();
    my %nodes         = $self->as_node_list();
    # output format is the actual PRE followed by all found strings
    $self->acyclic($self->get_starting(),\%dflabel,$lastDFLabel,\%nodes,\@string);
}

sub acyclic {
  my $self = shift;
  my $startNode = shift;
  my $dflabel_ref = shift;
  my $lastDFLabel = shift;
  my $nodes = shift;
  my $string = shift;
  # tree edge detection
  if (!exists($dflabel_ref->{$startNode})) {
    $dflabel_ref->{$startNode} = ++$lastDFLabel;  # the order inwhich this link was explored
    foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
      if (!exists($dflabel_ref->{$adjacent})) {      # initial tree edge
        foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
	  push(@{$string},$symbol);
          $self->acyclic($adjacent,\%{$dflabel_ref},$lastDFLabel,\%{$nodes},\@{$string});
	  if ($self->array_is_subset([$adjacent],[$self->get_accepting()])) { #< proof of concept
            printf("%s\n",join('',@{$string}));
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
};

sub as_dft_strings {
  my $self = shift;
  my $depth = 1;
  $depth = shift if (1 < $_[0]);
  my %dflabel        = (); # scoped lookup table for dflable
  my %nodes          = $self->as_node_list();
  foreach (keys(%nodes)) {
    $dflabel{$_} = []; # initialize container (array) for multiple dflables for each node
  }
  my $lastDFLabel    =  0;
  my @string         = ();
  $self->dft($self->get_starting(),[$self->get_accepting()],\%dflabel,$lastDFLabel,\%nodes,\@string,$depth); 
}

sub dft {
  my $self = shift;
  my $startNode    = shift;
  my $goals_ref    = shift;
  my $dflabel_ref  = shift;
  my $lastDFLabel  = shift;
  my $nodes        = shift;
  my $string       = shift;
  my $DEPTH        = shift;
  # add start node to path
  my $c1 = @{$dflabel_ref->{$startNode}}; # get number of elements
  if ($DEPTH >= $c1) {  
    push(@{$dflabel_ref->{$startNode}},++$lastDFLabel);
    foreach my $adjacent (keys(%{$nodes->{$startNode}})) {
      my $c2 = @{$dflabel_ref->{$adjacent}};
      if ($DEPTH > $c2) {   # "initial" tree edge
        foreach my $symbol (@{$nodes->{$startNode}{$adjacent}}) {
	  push(@{$string},$symbol);
	  $self->dft($adjacent,[@{$goals_ref}],$dflabel_ref,$lastDFLabel,$nodes,[@{$string}],$DEPTH);
	  # assumes some base path found
          if ($self->array_is_subset([$adjacent],[@{$goals_ref}])) { 
            printf("%s\n",join('',@{$string}));    
  	  } 
          pop(@{$string}); 
        } 
      }
    } # remove startNode entry to facilitate acyclic path determination
    pop(@{$dflabel_ref->{$startNode}});
    $lastDFLabel--;
  }    
};

1;

__END__

=head1 NAME

FLAT::DFA - Deterministic finite automata

=head1 SYNOPSIS

A FLAT::DFA object is a finite automata whose transitions are labeled
with single characters. Furthermore, each state has exactly one outgoing
transition for each available label/character.

=head1 USAGE

FLAT::DFA is a subclass of FLAT::NFA and its objects provide the same
methods.
