package Squatting::View;

use strict;
use warnings;
no  warnings 'redefine';

use Squatting ':views';

our $AUTOLOAD;

# constructor
sub new {
  my $class = shift;
  my $name  = shift;
  bless { name => $name, @_ } => $class;
}

# name of view
sub name : lvalue {
  $_[0]->{name};
}

# $content = $view->render($template)       # render $template
# $content = $view->render($template, '_')  # render the generic template
sub _render {
  my ($self, $template, $vars, $alt) = @_;
  if (exists $self->{layout} && ($template !~ /^_/)) {
    $template = $alt if defined $alt;
    join "", $self->{layout}($self, $vars, $self->{$template}($self, $vars));
  } else {
    $template = $alt if defined $alt;
    join "", $self->{$template}($self, $vars);
  }
}

# forward to _render()
sub AUTOLOAD {
  my ($self, $vars) = @_;
  my $template = $AUTOLOAD;
  $template =~ s/.*://;
  if (exists $self->{$template} && ref($self->{$template}) eq 'CODE') {
    $self->_render($template, $vars);
  } elsif (exists $self->{_}) {
    $self->_render($template, $vars, '_');
  } else {
    die("$template cannot be rendered.");
  }
}

sub DESTROY { }

1;

__END__

=head1 NAME

Squatting::View - default view class for Squatting

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: t ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: f ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
