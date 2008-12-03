package Squatting::H;
use strict;
use Clone;
use JSON::XS;

our $AUTOLOAD;

# Object->new(\%merge) -- constructor
sub new {
  my ($class, $opts) = @_;
  $opts ||= {};
  bless { %$opts } => $class;
}

# $object->merge(\%merge) -- merge keys and values of another hashref into $self
sub merge {
  my ($self, $merge) = @_;
  for (keys %$merge) {
    $self->{$_} = $merge->{$_};
  }
  $self;
}

# $object->clone(\%merge) -- copy constructor
sub clone {
  my ($self, $merge) = @_;
  my $clone = Clone::clone($self);
  $clone->merge($merge) if ($merge);
  $clone;
}

# $object->slots -- keys of underlying hashref of $object
sub slots {
  keys %{$_[0]}
}

# $object->as_hash -- unbless
sub as_hash {
  +{ %{$_[0]} };
}
*to_hash = \&as_hash;

# $object->as_json -- serialize $object as json
sub as_json {
  my ($self) = @_;
  if ($self->{to_json}) {
    $self->{to_json}->($self);
  } else {
    encode_json($self->as_hash);
  }
}
*to_json = \&as_json;
*TO_JSON = \&as_json;

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

Squatting::H - a slot based object for my amusement

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 API

=head2 Object Construction

=head3 $object = Squatting::H->new(\%merge)

                         
=head3 $object = $object->merge(\%merge)


=head3 $object2 = $object->clone(\%merge)


=head2 General

=head3 @slot_names = $object->slots;

=head3 $object->as_hash

=head3 $object->to_hash



=head3 $object->as_json

=head3 $object->to_json

=head3 $object->TO_JSON


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
