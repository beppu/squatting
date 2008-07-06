package Squatting::On::Catalyst;

use strict;
no  strict 'refs';
use warnings;
use Class::C3;
use Data::Dump 'pp';

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
  $cc->v       = $cat->stash;
  $cc->state   = $cat->session if ($cat->can('session'));
  $cc->log     = $cat->log     if ($cat->can('log'));
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

=head1 NAME

Squatting::On::Catalyst - embed a Squatting app into a Catalyst app

=head1 SYNOPSIS

Add these 4 lines to your Catalyst app's Root Controller to embed a Squatting
App.

  use App 'On::Catalyst'
  App->init;
  App->relocate('/somewhere')
  sub somewhere : Local { App->catalyze($_[1]) }

=head1 DESCRIPTION

The purpose of this module is to allow Squatting apps to be embedded inside
Catalyst apps.  This is done by adding a C<catalyze> method to the Squatting
app that knows how to "translate" between Catalyst and Squatting.  To use this
module, pass the string C<'On::Catalyst'> to the C<use> statement that loads
your Squatting app.

=head1 API

=head2 All Your Framework Are Belong To Us

=head3 App->catalyze($c)

This method takes a Catalyst object, and uses the information it contains to
let the Squatting app handle one HTTP request.  First, it translates the
Catalyst::Request object into terms Squatting can understand.  Then it lets
the Squatting app handle the request.  Finally, it takes the Squatting app's
output and populates the Catalyst::Response object.  When this method is done,
the Catalyst object should have everything it needs to send back a complete
HTTP response.

B<NOTE>:  If you want to communicate something from the Catalyst app to the
Squatting app, you can put data in $c->stash or $c->session before calling
catalyze().  From inside a Squatting controller, these can be accessed via
$self->v and $self->state.  Squatting controllers also get access to
Catalyst's logging object via $self->log.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Request>, L<Catalyst::Response>

=cut
