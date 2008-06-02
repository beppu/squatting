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
  $self->{template} = $template;
  if (exists $self->{layout} && ($template !~ /^_/)) {
    $template = $alt if defined $alt;
    $self->{layout}($self, $vars, $self->{$template}($self, $vars));
  } else {
    $template = $alt if defined $alt;
    $self->{$template}($self, $vars);
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

=head1 NAME

Squatting::View - default view class for Squatting

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 API

=head2 Methods

=head3 Squatting::View->new($name, %methods)

=head3 $v->name

=head3 $v->$template

=head1 SEE ALSO

L<Squatting>,
L<Squatting::Controller>

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
