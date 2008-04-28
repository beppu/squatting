package Squatting::View;

use strict;
use warnings;

use Squatting ':views';

our $AUTOLOAD;

# constructor
sub new {
  my $class = shift;
  my $name  = shift;
  bless({ name => $name, @_ } => $class);
}

# name of view
sub name {
  exists $_[1] ? $_[0]->{name} = $_[1] : $_[0]->{name};
}

# $content = $view->render($template)
sub _render {
  my ($self, $template) = @_;
  if (exists $self->{layout} && ($template !~ /^_/)) {
    join "", $self->{layout}( $self->{$template}() );
  } else {
    join "", $self->{$template}();
  }
}

# forward to _render()
sub AUTOLOAD {
  my $self = shift;
  my $x = $AUTOLOAD;
  $x =~ s/.*://;
  if (exists $self->{$x} && ref($self->{$x}) eq 'CODE') {
    $self->_render($x);
  } elsif (exists $self->{_}) {
    $self->_render(q^_^);
  } else {
    die("$x cannot be rendered.");
  }
}

1;
