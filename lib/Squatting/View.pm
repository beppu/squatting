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

# $content = $view->render($template)       # render $template
# $content = $view->render($template, '_')  # render the generic template
sub _render {
  ($self, my($template, $alt)) = @_;
  if (exists $self->{layout} && ($template !~ /^_/)) {
    join "", $self->{layout}( $self->{$template}() );
  } else {
    $template = $alt if defined $alt;
    join "", $self->{$template}();
  }
}

# forward to _render()
sub AUTOLOAD {
  my $template = $AUTOLOAD;
  $template =~ s/.*://;
  if (exists $_[0]->{$template} && ref($_[0]->{$template}) eq 'CODE') {
    $_[0]->_render($template);
  } elsif (exists $_[0]->{_}) {
    $_[0]->_render($template, '_');
  } else {
    die("$template cannot be rendered.");
  }
}

1;
