package FLAT::XFA;

use strict;
use base 'FLAT::FA';

use FLAT::Transition::Simple;
use FLAT::Symbol::String;

=head1 NAME

FLAT::XFA - Nondeterministic finite automata

=head1 SYNOPSIS

A FLAT::XFA object is a finite automata whose transitions are labeled
either with characters or the empty string (epsilon).

=cut

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{TRANS_CLASS} = "FLAT::Transition::Simple";
    $self->{ALPHA_CLASS} = "FLAT::Symbol::String";
    return $self;
}

sub singleton {
    my ($class, $char) = @_;
    my $xfa = $class->new;

    if (not defined $char) {
        $xfa->add_states(1);
        $xfa->set_starting(0);
    } elsif ($char eq "") {
        $xfa->add_states(1);
        $xfa->set_starting(0);
        $xfa->set_accepting(0);
    } else {
        $xfa->add_states(2);
        $xfa->set_starting(0);
        $xfa->set_accepting(1);
        $xfa->set_transition(0, 1, $char);
    }
    return $xfa;
}

sub as_xfa { $_[0]->clone }

sub union {
    my @xfas = map { $_->as_xfa } @_;    
    my $result = $xfas[0]->clone;    
    $result->_swallow($_) for @xfas[1 .. $#xfas];
    $result;
}

sub concat {
    my @xfas = map { $_->as_xfa } @_;
    
    my $result = $xfas[0]->clone;
    my @newstate = ([ $result->get_states ]);
    my @start = $result->get_starting;

    for (1 .. $#xfas) {
        push @newstate, [ $result->_swallow( $xfas[$_] ) ];
    }

    $result->unset_accepting($result->get_states);
    $result->unset_starting($result->get_states);
    $result->set_starting(@start);
    
    for my $xfa_id (1 .. $#xfas) {
        for my $s1 ($xfas[$xfa_id-1]->get_accepting) {
        for my $s2 ($xfas[$xfa_id]->get_starting) {
            $result->set_transition(
                $newstate[$xfa_id-1][$s1],
                $newstate[$xfa_id][$s2], "" );
        }}
    }

    $result->set_accepting(
        @{$newstate[-1]}[ $xfas[-1]->get_accepting ] );

    $result;
}

sub kleene {
    my $result = $_[0]->clone;
    
    my ($newstart, $newfinal) = $result->add_states(2);
    
    $result->set_transition($newstart, $_, "")
        for $result->get_starting;
    $result->unset_starting( $result->get_starting );
    $result->set_starting($newstart);

    $result->set_transition($_, $newfinal, "")
        for $result->get_accepting;
    $result->unset_accepting( $result->get_accepting );
    $result->set_accepting($newfinal);

    $result->set_transition($newstart, $newfinal, "");    
    $result->set_transition($newfinal, $newstart, "");
    
    $result;
}

sub reverse {
    my $self = $_[0]->clone;
    $self->_transpose;
    
    my @start = $self->get_starting;
    my @final = $self->get_accepting;
    
    $self->unset_accepting( $self->get_states );
    $self->unset_starting( $self->get_states );
    
    $self->set_accepting( @start );
    $self->set_starting( @final );
    
    $self;
}

###########

sub is_empty {
    my $self = shift;
    
    my @queue = $self->get_starting;
    my %seen = map { $_ => 1 } @queue;
    
    while (@queue) {
        return 0 if grep { $self->is_accepting($_) } @queue;
        @queue = grep { !$seen{$_}++ } $self->successors(\@queue);
    }
    return 1;
}

sub is_finite {
    my $self = shift;
    
    my @alphabet = $self->alphabet;
    return 1 if @alphabet == 0;
    
    my @queue = $self->get_starting;
    my %seen = map { $_ => 1 } @queue;
    
    while (@queue) {
        @queue = grep { !$seen{$_}++ } $self->successors(\@queue);
    }
    
    for my $s ( grep { $self->is_accepting($_) } keys %seen ) {
        @queue = $self->epsilon_closure($s);
        %seen  = map { $_ => 1 } @queue;
        
        while (@queue) {
            my @next = $self->epsilon_closure(
                            $self->successors(\@queue, \@alphabet) );

            return 0 if grep { $s eq $_ } @next;
            @queue = grep { !$seen{$_}++ } @next;
        }
    }
    return 1;
}

sub epsilon_closure {
    my ($self, @states) = @_;
    my %seen  = map { $_ => 1 } @states;
    my @queue = @states;
    
    while (@queue) {
        @queue = grep { ! $seen{$_}++ } $self->successors( \@queue, "" );
    }
    
    keys %seen;
}


sub contains {
    my ($self, $string) = @_;

    my @active = $self->epsilon_closure( $self->get_starting );    
    for my $char (split //, $string) {
        return 0 if ! @active;
        @active = $self->epsilon_closure( $self->successors(\@active, $char) );
    }
    return !! grep { $self->is_accepting($_) } @active;
}

sub trace {
    my ($self, $string) = @_;

    my @trace = ([ $self->epsilon_closure( $self->get_starting ) ]);
    
    for my $char (split //, $string) {
        push @trace,
            [ $self->epsilon_closure( $self->successors($trace[-1], $char) ) ];
    }
    return @trace;
}
############

sub _extend_alphabet {
    my ($self, @alpha) = @_;
    
    my %alpha = map { $_ => 1 } @alpha;
    delete $alpha{$_} for $self->alphabet;

    return if not keys %alpha;

    my $trash = $self->add_states(1);
    for my $state ($self->get_states) {
        next if $state eq $trash;
        for my $char (keys %alpha) {
            $self->add_transition($state, $trash, $char);
        }
    }
    $self->add_transition($trash, $trash, $self->alphabet);
}

######## transformations

# subset construction
sub as_dfa {
    my $self = shift;
    
    my $result = FLAT::DFA->new;
    my %subset;
    
    my %final = map { $_ => 1 } $self->get_accepting;
    my @start = sort { $a <=> $b } $self->epsilon_closure( $self->get_starting );

    my $start = $subset{ _SET_ID(@start) } = $result->add_states(1);
    $result->set_starting($start);
    
    $result->set_accepting( $start )
        if grep $_, @final{@start};

    my @queue = (\@start);
    while (@queue) {
        my @states = @{ shift @queue };
        my $S      = $subset{ _SET_ID(@states) };
        
        for my $symb ($self->alphabet) {
            my @to = $self->epsilon_closure(
                            $self->successors(\@states, $symb) );

            if ( not exists $subset{_SET_ID(@to)} ) {
                push @queue, \@to;
                my $T = $subset{_SET_ID(@to)} = $result->add_states(1);
                $result->set_accepting($T)
                    if grep $_, @final{@to};
            }
            
            $result->add_transition($S, $subset{ _SET_ID(@to) }, $symb);
        }
    }

    $result;
}

############ Formatted output

# Format that Dr. Sukhamay KUNDU likes to use in his assignments :)
# This format is just a undirected graph - so transition and state info is lost

sub as_undirected {
    my $self = shift;
    my @symbols = $self->alphabet();
    my @states = $self->get_states(); 
    my %edges = ();
    foreach (@states)  {
      my $s = $_;
      foreach (@symbols) {
        my $a = $_;
	# foreach state, get all nodes connected to it; ignore symbols and
	# treat transitions simply as directed
	push(@{$edges{$s}},$self->successors($s,$a));
	foreach ($self->successors($s,$a)) {
  	  push(@{$edges{$_}},$s);	
	}
      }
    }
    my @lines = (($#states+1));
    foreach (sort{$a <=> $b;}(keys(%edges))) { #<-- iterate over numerically sorted list of keys
      @{$edges{$_}} = sort {$a <=> $b;} $self->array_unique(@{$edges{$_}}); #<- make items unique and sort numerically
      push(@lines,sprintf("%s(%s):%s",$_,($#{$edges{$_}}+1),join(' ',@{$edges{$_}})));
    }
    return join("\n",@lines);
 }

# Format that Dr. Sukhamay KUNDU likes to use in his assignments :)
# This format is just a directed graph - so transition and state info is lost

sub as_digraph {
    my $self = shift;
    my @symbols = $self->alphabet();
    my @states = $self->get_states(); 
    my @lines = ();
    foreach (@states)  {
      my $s = $_;
      my @edges = ();
      foreach (@symbols) {
        my $a = $_;
	# foreach state, get all nodes connected to it; ignore symbols and
	# treat transitions simply as directed
	push(@edges,$self->successors($s,$a));
      }
      @edges = sort {$a <=> $b;} $self->array_unique(@edges); #<- make items unique and sort numerically
      push(@lines,sprintf("%s(%s): %s",$s,($#edges+1),join(' ',@edges)));
    }
    return sprintf("%s\n%s",($#states+1),join("\n",@lines));
}


# Graph Description Language, aiSee, etc
sub as_gdl {
    my $self = shift;
    
    my @states = map {
        sprintf qq{node: { title:"%s" shape:circle borderstyle: %s}\n},
            $_,
            ($self->is_accepting($_) ? "double bordercolor: red" : "solid")
    } $self->get_states;
    
    my @trans;
    for my $s1 ($self->get_states) {
    for my $s2 ($self->get_states) {
        my $t = $self->get_transition($s1, $s2);
        
        if (defined $t) {
            push @trans, sprintf qq[edge: { source: "%s" target: "%s" label: "%s" arrowstyle: line }\n],
                $s1, $s2, $t->as_string;
        }
    }}
  
    return sprintf "graph: {\ndisplay_edge_labels: yes\n\n%s\n%s}\n",
        join("", @states),
        join("", @trans);
}

# Graphviz: dot, etc
## digraph, directed
sub as_graphviz {
    my $self = shift;
    
    my @states = map {
        sprintf qq{%s [label="%s",shape=%s]\n},
            $_,
            ($self->is_starting($_) ? "start ($_)" : "$_"),
            ($self->is_accepting($_) ? "doublecircle" : "circle")
    } $self->get_states;
    
    my @trans;
    for my $s1 ($self->get_states) {
    for my $s2 ($self->get_states) {
        my $t = $self->get_transition($s1, $s2);
        
        if (defined $t) {
            push @trans, sprintf qq[%s -> %s [label="%s"]\n],
                $s1, $s2, $t->as_string;
        }
    }}
    
    return sprintf "digraph G {\ngraph [rankdir=LR]\n\n%s\n%s}\n",
        join("", @states),
        join("", @trans);
}
## undirected
sub as_undirected_graphviz {
    my $self = shift;
    
    my @states = map {
        sprintf qq{%s [label="%s",shape=%s]\n},
            $_,
            ("$_"),
            ("circle")
    } $self->get_states;
    
    my @trans;
    for my $s1 ($self->get_states) {
    for my $s2 ($self->get_states) {
        my $t = $self->get_transition($s1, $s2);
        
        if (defined $t) {
            push @trans, sprintf qq[%s -- %s\n],
                $s1, $s2, $t->as_string;
        }
    }}
    
    return sprintf "graph G {\ngraph [rankdir=LR]\n\n%s\n%s}\n",
        join("", @states),
        join("", @trans);
}

sub _SET_ID { return join "\0", sort { $a <=> $b } @_; }

sub as_summary {
    my $self = shift;
    my $out = ''; 
    $out .= sprintf ("States         : ");
    my @start;
    my @final;
    foreach ($self->get_states()) {
      $out .= sprintf "'$_' ";
      if ($self->is_starting($_)) {
        push(@start,$_);
      }
      if ($self->is_accepting($_)) {
        push(@final,$_);
      }
    }
    $out .= sprintf ("\nStart State    : '%s'\n",join('',@start));
    $out .= sprintf ("Final State(s) : ");
    foreach (@final) {
      $out .= sprintf "'$_' ";
    }
    $out .= sprintf ("\nAlphabet       : ");
    foreach ($self->alphabet()) {
      $out .= sprintf "'$_' ";
    }
    $out .= sprintf ("\nTransitions    :\n");
    my @trans;
     for my $s1 ($self->get_states) {
     for my $s2 ($self->get_states) {
         my $t = $self->get_transition($s1, $s2);
         if (defined $t) {
             push @trans, sprintf qq[%s -> %s on "%s"\n],
                 $s1, $s2, $t->as_string;
         }
     }}
    $out .= join('',@trans);
    return $out;        
}

1;

__END__

=head1 USAGE

In addition to implementing the interface specified in L<FLAT>, FLAT::XFA
objects provide the following XFA-specific methods:

=over

=item $xfa-E<gt>epsilon_closure(@states)

Returns the set of states (without duplicates) which are reachable from
@states via zero or more epsilon-labeled transitions.

=item $xfa-E<gt>trace($string)

Returns a list of N+1 arrayrefs, where N is the length of $string. The
I-th arrayref contains the states which are reachable from the starting
state(s) of $xfa after reading I characters of $string. Correctly accounts
for epsilon transitions.

=item $xfa-E<gt>as_undirected

Outputs FA in a format that may be easily read into an external program as
a description of an undirected graph.

=item $xfa-E<gt>as_digraph

Outputs FA in a format that may be easily read into an external program as
a description of an directed graph.

=item $xfa-E<gt>as_gdl

Outputs FA in Graph Description Language (GDL), including directed transitions 
with symbols and state names labeled.

=item $xfa-E<gt>as_graphviz

Outputs FA in Graphviz format, including directed transitions with symbols and
and state names labeled.  This output may be directly piped into any of the
Graphviz layout programs, and in turn one may output an image using a single
commandline instruction. C<fash> uses this function to implement its "xfa2gv"
command:

 fash xfa2gv "a*b" | dot -Tpng > xfa.png

=item $xfa-E<gt>as_undirected_graphviz

Outputs FA in Graphviz format, with out the directed transitions or labels.
The output is suitable for any of the Graphvize layout programs, as discussed
above.

=item $xfa-E<gt>as_summary

Outputs a summary of the FA, including its states, symbols, and transition matrix.
It is useful for manually validating what the FA looks like.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
