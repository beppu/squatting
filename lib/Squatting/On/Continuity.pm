package Squatting::On::Continuity;

use strict;
use warnings;
use Coro;
use Continuity;

# XXX - WORK IN PROGRESS

# \%env = e($http_request)
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
  +{ map {
    if ($i{$_} =~ /\0/) {
      $_ => [ split("\0", $i{$_}) ];
    } else {
      $_ => $i{$_};
    }
  } keys %i }
}

# \%cookies = c($cookie_header)  # Parse Cookie header(s).
sub c {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
}

# init_cc($controller, $continuity_request) -- initialize a controller clone
sub init_cc {
  my ($c, $cr) = @_;
  my $cc = $c->clone;
  $cc->cr      = $cr;
  $cc->env     = e($cr->http_request);
  $cc->cookies = c($self->env->{HTTP_COOKIE});
  $cc->input   = i(join('&', grep { defined } ($self->env->{QUERY_STRING}, $cr->request->content)));
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  $cc->status  = 200;
  $cc;
}

# App->continue(%opts) -- Start Continuity's main loop.
sub continue {
  my $app = shift;

  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port     => 4234,
    mapper   => Squatting::Mapper->new(
      app      => $app,
      callback => sub {
        my $cr = shift;
        my ($c, $p)  = &{$app."::D"}($cr->uri->path);
        my $cc       = init_cc($c, $cr);
        my $content  = $app->service($cc, @$p);
        my $response = HTTP::Response->new(
          $cc->status,
          HTTP::Status::status_message($cc->status),
          [%{$cc->{headers}}],
          $content
        );
        $cr->conn->send_response($response);
        $cr->end_request;
      },
      @_
    ),
    @_
  )->loop;
}

$SIG{PIPE} = sub { Coro::terminate(0) };

1;
