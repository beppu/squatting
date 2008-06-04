package Squatting::H;
use strict;
use selfvars;
use base 'Exporter';

our $AUTOLOAD;
our @EXPORT = qw(H);

sub H {
  Squatting::H->new(@_)
}

sub new {
  bless { %opts } => $_[0];
}

sub clone {
  bless { %$self, %opts } => ref($self);
}

sub AUTOLOAD {
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

sub DESTROY {
}

1;
__END__
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
