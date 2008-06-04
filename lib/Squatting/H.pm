package Squatting::H;
use strict;
our $AUTOLOAD;

sub new {
  bless { @_[1..$#_] } => $_[0];
}

sub clone {
  bless { %{$_[0]}, @_[1..$#_] } => ref($_[0]);
}

sub AUTOLOAD {
  my $self = shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*://;
  if (exists $self->{$attr}) {
    if (ref($self->{$attr}) eq 'CODE') {
      return $self->{$attr}->($self, @_);
    } else {
      return $self->{$attr};
    }
  } else {
    return undef;
  }
}

sub DESTROY {
}

1;
