package Squatting::H;
use strict;
use warnings;
use Clone;

our $AUTOLOAD;

# Squatting::H->new(\%attributes) -- constructor
sub new {
  my ($class, $opts) = @_;
  $opts ||= {};
  CORE::bless { %$opts } => $class;
}

# Squatting::H->bless(\%attributes) -- like new() but directly bless $opts instead of making a shallow copy.
sub bless {
  my ($class, $opts) = @_;
  $opts ||= {};
  CORE::bless $opts => $class;
}

# $object->extend(\%attributes) -- extend keys and values of another hashref into $self
sub extend {
  my ($self, $extend) = @_;
  for (keys %$extend) {
    $self->{$_} = $extend->{$_};
  }
  $self;
}

# $object->clone(\%attributes) -- copy constructor
sub clone {
  my ($self, $extend) = @_;
  my $clone = Clone::clone($self);
  $clone->extend($extend) if ($extend);
  $clone;
}

# $object->slots -- keys of underlying hashref of $object
sub slots {
  keys %{$_[0]}
}

# $object->can($method) -- does the $object support this $method?
sub can {
  UNIVERSAL::can($_[0], $_[1]) || $_[0]->{$_[1]};
}

# $self->$method -- treat key values as methods
sub AUTOLOAD {
  my ($self, @args) = @_;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*://;
  if (ref($self->{$attr}) eq 'CODE') {
    $self->{$attr}->($self, @args)
  } else {
    if (@args) {
      $self->{$attr} = $args[0];
    } else {
      $self->{$attr};
    }
  }
}

sub DESTROY { }

1;

__END__

=head1 NAME

Squatting::H - a slot-based object that's vaguely reminiscent of Camping::H

=head1 SYNOPSIS

Behold, a glorified hashref that you can treat like an object:

  my $cat = Squatting::H->new({
    name => 'kurochan',
    meow => sub { "me" . "o" x length($_[0]->name) . "w" }
  });
  my $kitty = $cat->clone({ name => 'max' });

  $cat->name;                     # "kurochan"
  $kitty->name;                   # "max"
  $cat->meow;                     # "meoooooooow"
  $kitty->meow;                   # "meooow"
  $cat->age(3);                   # 3
  $kitty->age(2);                 # 2
  $kitty->slots;                  # qw(name meow age)

=head1 DESCRIPTION

This module implements a simple slot-based object system.  Objects in this
system are blessed hashrefs whose keys (aka slots) can be accessed by calling
methods with the same name as the key.  You can also assign coderefs to a slot
which will let you define custom methods for an object.

This object system does not implement inheritance, but you can create
derivatives of an object using the C<clone()> method which creates a deep copy
of your object.

=head1 API

=head2 Object Construction

=head3 $object = Squatting::H->new(\%attributes)

This method is used to construct a new object.  A hashref of attributes may be
passed to this method to initialize the object.  A shallow copy of
C<\%attributes> will then be created and blessed before being returned.

=head3 $object = Squatting::H->bless(\%attributes)

This is like new(), but it doesn't bother making a shallow copy of C<\%attributes>.
                         
=head3 $object = $object->extend(\%attributes)

This method will add new attributes to an object.  If the attributes already
existed, the new values will replace the old values.

=head3 $clone = $object->clone(\%attributes)

This method will create a deep clone of the object.  You may also pass in
a hashref of attributes that the cloned object should have.

=head2 General

=head3 $object->can($method)

UNIVERSAL::can has been overridden to be aware of the conventions used by
Squatting::H objects.  If a slot has been defined for the method that's passed
in, this method will return true.

=head3 @slot_names = $object->slots;

This method gives you a list of all the slots that have been defined
for this object.  It's essentially the same as saying:

  keys %$object

=head3 $value = $object->$slot

=head3 $value = $object->$slot($value)

This method lets you get and set the value of a slot.

  $object->foo(5);
  $object->foo;         # 5

If you pass in a coderef, it'll be treated as a method for your object.

  $object->double(sub {
    my ($self, $x) = @_;
    $x * 2;
  });
  $object->double(16)   # 32


=head1 SEE ALSO

L<http://camping.rubyforge.org/classes/Camping/H.html>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: f ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: f ***
# End: ***
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
