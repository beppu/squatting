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

  package App::Views;
  use Squatting 'views';
  our @V = (
    V(
      'html',
      layout => sub {
        my ($self, $v, @content) = @_;
        "(header @content footer)";
      },
      home => sub {
        my ($self, $v) = @_;
        "Hello, $v->{name}";
      },
      _ => sub {
        my ($self, $v) = @_;
        "You tried to render $self->{template} which was not defined.";
      },
      arbitrary_data => [ 'is', 'ok', 2 ],
    )
  );

=head1 DESCRIPTION

In Squatting, views are objects that contain many templates.  Templates
are represented by subroutine references that will be installed as methods
of a view object.  The job of a template is to take a hashref of variables
and return a string.

You may also define a special template named "layout" that's expected to
also take the output of another template and wrap it.

=head1 API

=head2 General Methods

=head3 Squatting::View->new($name, %methods)

The constructor takes a name and a hash of attributes and coderefs.

=head3 $v->name

This returns the name of the view.

=head2 Template Methods

=head3 $v->$template($v)

Any coderef that was given to the constructor may be called by name.
Templates should be passed in a hashref ($v) with variables for it
to use to generate the final output.

=head3 $v->layout($v, @content)

If you define a template named "layout", it'll be used to wrap the
content of all templates whose name do not begin with "_".  You can
use this feature to provide standard headers and footers for your
pages.

=head3 $v->_($v)

If you define a template named "_", this will act as a catch-all
that can be asked to render anything that wasn't explicitly defined.
It's like our version of AUTOLOAD().

B<NOTE>:  You can find out what they tried to render by inspecting
$self->{template}.

=head1 SEE ALSO

L<Squatting>,
L<Squatting::Controller>

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
