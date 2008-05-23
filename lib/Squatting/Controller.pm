package Squatting::Controller;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';

use CGI::Cookie;

use Squatting ':controllers';

our $AUTOLOAD;

# constructor
sub new {
  bless { name => $_[1], urls => $_[2], @_[3..$#_] } => $_[0];
}

# init w/ Continuity::Request
sub init {
  my ($self, $cr) = @_;
  $self->cr      = $cr;
  $self->env     = e($cr->http_request);
  $self->cookies = c($self->env->{HTTP_COOKIE});
  $self->input   = i(join('&', grep { defined } ($self->env->{QUERY_STRING}, $cr->request->content)));
  $self->headers = { 'Content-Type' => 'text/html' };
  $self->v       = {};
  $self->status  = 200;
  $self;
}

# (shallow) copy constructor
sub clone {
  bless { %{$_[0]}, @_[1..$#_] } => ref($_[0]);
}

# name    - name of controller
# urls    - arrayref of URL patterns that this controller responds to
# cr      - Continuity::Request object
# env     - incoming request headers and misc info like %ENV in the CGI days
# cookies - incoming *AND* outgoing cookies
# input   - incoming CGI variables
# v       - outgoing vars
# status  - outgoing HTTP Response status
# headers - outgoing HTTP headers
for my $m qw(name urls cr env cookies input v status headers) {
  *{$m} = sub : lvalue { $_[0]->{$m} }
}

# method for handling HTTP GET requests
sub get {
  $_[0]->{get}->(@_);
}

# method for handling HTTP POST requests
sub post {
  $_[0]->{post}->(@_);
}

# $content = $self->render($template, $vars)
sub render {
  my ($self, $template, $vn) = @_;
  my $view;
  if (defined($vn)) {
    $view = ${$app."::Views::V"}{$vn}; #  hash
  } else {                             #    vs
    $view = ${$app."::Views::V"}[0];   # array -- Perl provides a lot of 'namespaces' so why not use them?
  }
  $view->$template($self->v);
}

# $self->redirect($url, $status_code)
sub redirect {
  my ($self, $l, $s) = @_;
  $self->headers->{Location} = $l || '/';
  $self->status = $s || 302;
}

# \%env = e($http_request)  # Get request headers from HTTP::Request.
sub e {
  my $r = shift;
  my %env;
  my $uri = $r->uri;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = $uri->path;
  $env{REQUEST_URI}    = $uri->path_query;
  $env{REQUEST_METHOD} = $r->method;
  $r->scan(sub{
    my ($header, $value) = @_;
    my $key = uc $header;
    $key =~ s/-/_/g;
    $key = "HTTP_$key";
    $env{$key} = $value;
  });
  \%env;
}

# \%input = i($query_string)  # Extract CGI parameters from QUERY_STRING
sub i {
  my $q = CGI->new($_[0]);
  my %i = $q->Vars;
  my %input = map {
    if ($i{$_} =~ /\0/) {
      $_ => [ split("\0", $i{$_}) ];
    } else {
      $_ => $i{$_};
    }
  } keys %i;
  \%input;
}

# \%cookies = c($cookie_header)  # Parse Cookie header(s).
sub c {
  { CGI::Cookie->parse($_[0]) };
}

# default 404 controller
my $not_found = sub { $_[0]->status = 404; $_[0]->env->{REQUEST_PATH}." not found." };
our $r404 = Squatting::Controller->new(
  R404 => [],
  get  => $not_found,
  post => $not_found
);

1;

=head1 NAME

Squatting::Controller - default controller class for Squatting

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
