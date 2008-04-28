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

# arrayref of URL patterns that this controller responds to
sub urls {
  if (@_ > 1) {
    $_[0]->{urls} = $_[1]
  } else {
    $_[0]->{urls}
  }
}

# name of controller
sub name {
  exists $_[1] ? $_[0]->{name} = $_[1] : $_[0]->{name};
}

# method for handling HTTP GET requests
sub get {
  $self = shift;
  $self->{get}->(@_);
}

# method for handling HTTP POST requests
sub post {
  $self = shift;
  $self->{post}->(@_);
}

# default 404 controller
my $not_found = sub { "$ENV{REQUEST_PATH} not found." };
our $r404 = Squatting::Controller->new(
  'R404' => [],
  get    => $not_found,
  post   => $not_found
);

1;

__END__

=head1 NAME

Squatting::Controller - default controller class for Squatting

=cut
