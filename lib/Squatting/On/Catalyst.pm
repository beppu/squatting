package Squatting::On::Catalyst;

use strict;
no  strict 'refs';
use warnings;

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

my %p;

$p{e} = sub {
  my $cat = shift;
  my $req = $cat->req;
  my $uri = $req->uri;
  my %env;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = '/' . $req->path;
  $env{REQUEST_URI}    = "$env{REQUEST_PATH}?$env{QUERY_STRING}";
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
};

$p{c} = sub {
  my $cat = shift;
  my $c = $cat->req->cookies;
  my %k;
  $k{$_} = $$c{$_}->value for (keys %$c);
  \%k;
};

# init_cc($controller, $catalyst) -- initialize a controller clone
$p{init_cc} = sub {
  my ($c, $cat) = @_;
  my $cc = $c->clone;
  $cc->env     = $p{e}->($cat);
  $cc->cookies = $p{c}->($cat);
  $cc->input   = $cat->req->parameters;
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = $cat->stash;
  $cc->state   = $cat->session if ($cat->can('session'));
  $cc->log     = $cat->log     if ($cat->can('log'));
  $cc->status  = 200;
  $cc;
};

sub catalyze {
  my ($app, $cat) = @_;
  my ($c,   $p)   = &{ $app . "::D" }('/'.$cat->request->path);
  my $cc = $p{init_cc}->($c, $cat);
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

In summary:

  Catalyst                              Squatting
  --------                              ---------
  $c->stash                             $self->v
  $c->session                           $self->state
  $c->log                               $self->log

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Request>, L<Catalyst::Response>

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
