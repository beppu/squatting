package Squatting::Controller;

use strict;
use warnings;

use Squatting ':controllers';

our $AUTOLOAD;

# constructor
sub new {
  my $class = shift;
  my $name  = shift;
  my $urls  = shift;
  bless { name => $name, urls => $urls, @_ } => $class;
}

# (shallow) copy constructor
sub clone {
  bless { %{$_[0]} } => ref($_[0]);
}

# name of controller
sub name : lvalue {
  $_[0]->{name}
}

# arrayref of URL patterns that this controller responds to
sub urls : lvalue {
  $_[0]->{urls}
}

# name of view to use for rendering
sub view : lvalue {
  $_[0]->{view}
}

# name of the app this controller belongs to
sub app : lvalue {
  $_[0]->{app}
}

# Continuity::Request object
sub c : lvalue {
  $_[0]->{c}
}

# method for handling HTTP GET requests
sub get {
  my $self = shift;
  $self->{get}->(@_);
}

# method for handling HTTP POST requests
sub post {
  my $self = shift;
  $self->{post}->(@_);
}

# $content = $self->render($template, $vars)
sub render { 
  my ($self, $template, $vars) = @_;
  my $view;
  my $vn  = $self->view;
  my $app = $self->app;
  if (defined($vn)) {
    $view = ${$app."::Views::V"}{$vn}; #  hash
  } else {                             #    vs
    $view = ${$app."::Views::V"}[000]; # array -- Perl provides a lot of 'namespaces' so why not use them?
  }
  $view->$template($vars);
}

# forward unknown methods to Continuity::Request object
sub AUTOLOAD {
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.*://;
  $self->c->$method(@_);
}

sub DESTROY { }

# default 404 controller
my $not_found = sub { $status = 404; "$ENV{REQUEST_PATH} not found." };
our $r404 = Squatting::Controller->new(
  R404 => [],
  get  => $not_found,
  post => $not_found
);

1;

__END__

=head1 NAME

Squatting::Controller - default controller class for Squatting

=cut
