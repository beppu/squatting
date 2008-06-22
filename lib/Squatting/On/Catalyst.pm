package Squatting::On::Catalyst;

use strict;
use warnings;

# XXX - WORK IN PROGRESS

# In order to embed a Squatting app into an app written in another framework,
# we need to be able to do the following things.
#
# get incoming CGI parameters
# get incoming HTTP request headers
# get incoming HTTP method
# set outgoing HTTP status
# set outgoing HTTP response headers
# set outgoing content

# init_cc($controller, $catalyst) -- initialize a controller clone
sub init_cc {
  my ($c, $cat) = @_;
}

sub catalyze {
  my ($app, $cat) = @_;
  my ($c, $p)  = &{$app."::D"}($cat->request->path);
  my $cc       = init_cc($c, $cat);
  my $content  = $app->service($cc, @$p);
  $cat->response->status($cc->status);
  $cat->response->body($content);
  $cat->response->headers;
  $cat;
}

1;
