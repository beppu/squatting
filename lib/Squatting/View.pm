package Squatting::View;

#use strict;
#use warnings;
#no  warnings 'redefine';

#our $AUTOLOAD;

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

# name of view
sub headers : lvalue {
  $_[0]->{headers};
}

# $content = $view->_render($template, $vars)       # render $template
# $content = $view->_render($template, $vars, '_')  # render generic template
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
      'example',
      layout => sub {
        my ($self, $v, $content) = @_;
        "(header $content footer)";
      },
      home => sub {
        my ($self, $v) = @_;
        "Hello, $v->{name}";
      },
      _ => sub {
        my ($self, $v) = @_;
        "You tried to render $self->{template} which was not defined.";
      },
      arbitrary_data => [ { is => 'ok' }, 2 ],
    )
  );

=head1 DESCRIPTION

In Squatting, views are objects that contain many templates.  Templates are
represented by coderefs that will be treated as methods of a view object.  The
job of a template is to take a hashref of variables and return a string.  

Typically, the hashref of variables will be the same as what's in
C<$controller-E<gt>v>.  This is important to note, because if you want a session
variable in C<$controller-E<gt>state> to affect the template, you have to put
it in C<$controller-E<gt>v>.

=head1 API

=head2 General Methods

=head3 $view = Squatting::View->new($name, %methods)

The constructor takes a name and a hash of attributes and coderefs.
Note that the name must be unique within the package the view is defined.

=head3 $view->name

This returns the name of the view.

=head3 $view->headers

This returns a hashref of the outgoing HTTP headers.

=head2 Template Methods

=head3 $content = $view->$template($v)

Any coderef that was given to the constructor may be called by name.  Templates
should be passed in a hashref (C<$v>) with variables for it to use to generate
the final output.

=head3 $content = $view->layout($v, $content)

If you define a template named "layout", it'll be used to wrap the
content of all templates whose name do not begin with "_".  You can
use this feature to provide standard headers and footers for your
pages.

=head3 $content = $view->_($v)

If you define a template named "_", this will act as a catch-all
that can be asked to render anything that wasn't explicitly defined.
It's like our version of C<AUTOLOAD>.

B<NOTE>:  You can find out what they tried to render by inspecting
C<$self-E<gt>{template}>.

This feature is useful when you're using a file-based templating system like
Tenjin or Template Toolkit, and you don't want to write a template sub for
every single template.  Instead, you can make C<$self-E<gt>{template}>
correspond to a file on disk.

=head3 $view->{$template} = \&coderef

You are allowed to directly replace the template coderefs with your own.
The most common reason you'd do this would be to replace an app's default
layout with your own.

  $view->{layout} = sub {
    my ($self, $v, $content) = @_;
    # ...
  };

=head1 SEE ALSO

L<Squatting>,
L<Squatting::Controller>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
