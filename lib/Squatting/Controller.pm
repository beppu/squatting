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
sub cr : lvalue {
  $_[0]->{cr}
}

# incoming request headers and misc info like %ENV in the CGI days
sub env : lvalue {
  $_[0]->{env}
}

# incoming cookies
sub cookies : lvalue {
  $_[0]->{cookies}
}

# outgoing HTTP Response status
sub status {
  my ($self, $value) = @_;
  if (defined($value)) {
    $self->{status} = $value;
  } else {
    $self->{status};
  }
}

# outgoing HTTP headers
sub headers {
  my ($self, $name, $value) = @_;
  if (defined($value)) {
    $self->{headers}->{$name} = $value;
  } else {
    $self->{headers}->{$name};
  }
}

# outgoing cookies
sub set_cookie {
  my ($self, $name, $value) = @_;
  if (defined($value)) {
    $self->{set_cookie}->{$name} = $value;
  } else {
    $self->{set_cookie}->{$name};
  }
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

# $self->redirect($url, $status_code)
sub redirect {
  my ($self, $l, $s) = @_;
  $self->headers(Location => $l || '/');
  $self->status($s || 302);
}

# forward unknown methods to Continuity::Request object
sub AUTOLOAD {
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.*://;
  $self->cr->$method(@_);
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
