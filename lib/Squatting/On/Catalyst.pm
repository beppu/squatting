package Squatting::On::Catalyst;

use strict;
no  strict 'refs';
use warnings;
use Class::C3;
use Data::Dump 'pp';

# XXX - WORK IN PROGRESS

# In order to embed a Squatting app into an app written in another framework,
# we need to be able to do the following things.
#
# get incoming CGI parameters
# get incoming HTTP request headers
# get incoming `-cookies
# get incoming HTTP method
# set outgoing HTTP status
# set outgoing HTTP response headers
# set outgoing content

sub e {
  my $cat = shift;
  my $req = $cat->req;
  my $uri = $req->uri;
  my %env;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = $uri->path;
  $env{REQUEST_URI}    = $uri->path_query;
  $env{REQUEST_METHOD} = $req->method;
  my $h = $req->headers;
  $h->scan(sub{
    my ($header, $value) = @_;
    my $key = uc $header;
    $key =~ s/-/_/g;
    $key = "HTTP_$key";
    $env{$key} = $value;
  });
  \%env;
}

sub c {
  my $cat = shift;
  # i think this is wrong...  i may have to massage the data some more.
  $cat->req->cookies;
}

# init_cc($controller, $catalyst) -- initialize a controller clone
sub init_cc {
  my ($c, $cat) = @_;
  my $cc = $c->clone;
  $cc->env     = e($cat);
  $cc->cookies = c($cat);
  $cc->input   = $cat->req->parameters;
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  $cc->status  = 200;
  $cc;
}

sub catalyze {
  my ($app, $cat) = @_;
  my ($c,   $p)   = &{ $app . "::D" }($cat->request->uri->path);
  my $cc = init_cc($c, $cat);
  my $content = $app->service($cc, @$p);
  my $h       = $cat->response->headers;
  my $ch      = $cc->headers;
  for (keys %$ch) {
    $h->header($_ => $ch->{$_});
  }
  $cat->response->status($cc->status);
  $cat->response->body($content);
}

1;
