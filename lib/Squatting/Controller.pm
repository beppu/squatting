package Squatting::Controller;

use strict;
use warnings;

use Squatting ':controllers';

# constructor
sub new {
  my $class = shift;
  my $name  = shift;
  my $urls  = shift;
  bless({ name => $name, urls => $urls, @_ } => $class);
}

# (shallow) copy constructor
sub clone {
  bless { %{$_[0]} } => ref($_[0]);
}

# arrayref of URL patterns that this controller responds to
sub urls : lvalue {
  $_[0]->{urls}
}

# name of controller
sub name : lvalue {
  $_[0]->{name};
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
