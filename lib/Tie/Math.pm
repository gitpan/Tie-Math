package Tie::Math;

use strict;
require Exporter;
@Tie::Math::ISA = qw(Exporter);
@Tie::Math::EXPORT = qw(f n);
$Tie::Math::VERSION = '0.01';

# Need lvalue subroutines.
require 5.006;

use constant DEBUG => 0;


# Alas, I can't use Tie::StdHash and Tie::Hash is too bloody slow.
# So I'll just copy the meat of Tie::StdHash in here and do a little
# s///
sub STORE    { $_[0]->{hash}->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]->{hash}}; each %{$_[0]->{hash}} }
sub NEXTKEY  { each %{$_[0]->{hash}} }
sub EXISTS   { exists $_[0]->{hash}->{$_[1]} }
sub DELETE   { delete $_[0]->{hash}->{$_[1]} }
sub CLEAR    { %{$_[0]->{hash}} = () }


=pod

=head1 NAME

Tie::Math - Hashes which represent mathematical sequences.


=head1 SYNOPSIS

  use Tie::Math;
  tie %fibo, 'Tie::Math', sub { f(n) = f(n-1) + f(n-2) },
                          sub { f(0) = 1;  f(1) = 1 };

  # Calculate and print the fifth fibonacci number
  print $fibo{5};


=head1 DESCRIPTION

Defines arrays which represent mathematical sequences, such as the
fibonacci sequence.

=over 4

=item B<tie>

  tie %func, 'Tie::Math', \&function;
  tie %func, 'Tie::Math', \&function, \&initialization;

&function contains the definition of the mathematical function.  Use
the f() subroutine and $n index variable provided.  So to do a simple
exponential function represented by "f(n) = n**2":

    tie %exp, 'Tie::Math', sub { f($n) = $n**2 };

&initialization contains any special cases of the function you need to
define.  In the fibonacci example in the SYNOPSIS you have to define
f(0) = 1 and f(1) = 1;

    tie %fibo, 'Tie::Math', sub { f($n) = f($n-1) + f($n-2) },
                            sub { f(0) = 1;  f(1) = 1; };

The &initializaion routine is optional.

Each calculation is "memoized" so that for each element of the array the
calculation is only done once.

=cut

use vars qw($Obj $Idx $IsInit);

sub TIEHASH {
    my($class, $func, $init) = @_;

    my $self = bless {}, $class;

    $self->{func}  = $func;
    $self->{hash} = {};

    if( defined $init ) {
        local $Obj = $self;
        local $IsInit = 1;
        $init->();
    }

    return $self;
}


sub f : lvalue {
    my($idx) = $_[0];
    # Can't return an array element from an lvalue routine, but we
    # can return a dereferenced reference to it!
    warn "f() index - $idx\n"   if DEBUG;
    warn "\$Idx - $Idx\n"       if DEBUG;
    select(undef,undef,undef,0.250) if DEBUG;

    unless( $IsInit || exists $Obj->{hash}{$idx} || $Idx == $idx ) {
        $Obj->FETCH($idx);
    }

    my $tmp = \$Obj->{hash}{$idx};
    warn "tmp is $$tmp\n" if defined $$tmp && DEBUG;
    $$tmp;
}


sub n () {
    return $Idx;
}


sub FETCH {
    my($self, $idx) = @_;
    my $hash = $self->{hash};

    my($call_pack) = caller;

    warn "FETCH() idx is $idx\n" if DEBUG;
    warn "FETCH() calling pack is $call_pack\n" if DEBUG;

    unless( exists $hash->{$idx} ) {
        no strict 'refs';

        local $Obj = $self;
        local $IsInit = 0;
        local $Idx = $idx;

        $self->{func}->();
    }

    return $hash->{$idx};
}


1;
