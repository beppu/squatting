package Squatting::On::Continuity;

use strict;
no  strict 'refs';
#use warnings;
use Continuity;
use Squatting::Mapper;

# p for private  # this is my way of minimizing namespace pollution
my %p;

# \%env = e($http_request)
$p{e} = sub {
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
};

# \%input = i($query_string)  # Extract CGI parameters from QUERY_STRING
$p{i} = sub {
  my $q = CGI->new($_[0]);
  my %i = $q->Vars;
  +{ map {
    if ($i{$_} =~ /\0/) {
      $_ => [ split("\0", $i{$_}) ];
    } else {
      $_ => $i{$_};
    }
  } keys %i }
};

# \%cookies = c($cookie_header)  # Parse Cookie header(s).
$p{c} = sub {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
};

# init_cc($controller, $continuity_request)  # initialize a controller clone
$p{init_cc} = sub {
  my ($c, $cr) = @_;
  my $cc = $c->clone;
  $cc->cr      = $cr;
  $cc->env     = $p{e}->($cr->http_request);
  $cc->cookies = $p{c}->($cc->env->{HTTP_COOKIE});
  $cc->input   = $p{i}->(join('&', grep { defined } ($cc->env->{QUERY_STRING}, $cr->request->content)));
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  $cc->status  = 200;
  $cc;
};

# App->service($controller, @args)  # handle one http request
sub service {
  my ($app, $c, @args) = @_;
  # call original service()
  my $content = $app->next::method($c, @args);
  # afterward, do some Continuity-specific cookie munging
  if (my $cr_cookies = $c->cr->cookies) {
    $cr_cookies =~ s/^Set-Cookie: //;
    $c->headers->{'Set-Cookie'} = join("; ",
      grep { not /^\s*$/ } ($c->headers->{'Set-Cookie'}, $cr_cookies));
  }
  $content;
}

# App->continue(%opts)  # Start Continuity's main loop.
sub continue {
  my $app = shift;

  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port            => 4234,
    allowed_methods => [ qw(GET POST HEAD PUT DELETE) ],
    mapper          => Squatting::Mapper->new(
      app      => $app,
      callback => sub {
        my $cr = shift;
        my ($c, $p)  = &{$app."::D"}($cr->uri->path);
        my $cc       = $p{init_cc}->($c, $cr);
        my $content  = $app->service($cc, @$p);
        my $response = HTTP::Response->new(
          $cc->status,
          undef,
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

=head1 NAME

Squatting::On::Continuity - use Continuity as the server for your Squatting app

=head1 SYNOPSIS

Running a Squatting application on top of Continuity:

  use App 'On::Continuity';
  App->init;
  App->continue(port => 2012);

=head1 DESCRIPTION

The purpose of this module is to add a C<continue> method to your app that will
start a Continuity-based web server when invoked.  To use this module, pass the
string C<'On::Continuity'> to the C<use> statement that loads your Squatting
app.

=head1 API 

=head2 Continuity meets MVC (or just VC, actually)

=head3 App->continue(%options)

This method starts a Continuity-based web server.  The %options are passed
straight through to Continuity, and they let you specify things like what port
to run the server on.

=head1 EXPLANATION

=head2 The Special Powers of Continuity

L<Continuity> has 2 highly unusual (but useful) capabilities.

=over 4

=item 1. It can hold many simultaneous HTTP connections open.

=item 2. It can "pause" execution until the next request comes in.

=back

The easiest way to explain this is by example.

=head2 Becoming RESTless

Consider this controller which has an infinite loop in it.

  C(
    Count => [ '/@count' ],
    get => sub {
      my ($self) = @_;
      my $cr     = $self->cr;
      my $i      = 1;
      while (1) {
        $cr->print($i++);
        $cr->next;
      }
    },
    queue => { get => 'name_of_queue' }
  )

Here, the code is dropping down to the Continuity level.  The C<$cr> variable
contains a L<Continuity::Request> object, and with that in hand, we can try
something as audacious as an infinite loop.  However, this while loop does not
spin out of control and eat up all your CPU.  The C<$cr-E<gt>next> statement
will pause execution of the current coroutine, and it will wait until the
next HTTP request to come in.  Thus, you can hit reload multiple times and
watch C<$i> increment each time.

However, not just any HTTP request will wake this coroutine up.  To make
C<$cr-E<gt>next> stop blocking, a request with the following properties will
have to come in.

=over 4

=item It has to have the same session_id.

=item It has to be for the same controller.

=item It has to be a GET request.

=back

The key is this line:

  queue => { get => 'name_of_queue' }

When you're squatting on Continuity, you're allowed to define your controllers
with a C<queue> attribute.  It should contain a hashref where the keys are HTTP
methods (in lower case) and the values are unique strings that will be used
internally by Continuity to differentiate one queue of requests from another.

Every method mentioned in C<queue> will be given its own coroutine to run in.

=head2 Pausing for Other Events

TO BE CONTINUED...

For a sneak peak, take a look at the Chat application in the F<eg/> directory.

=head1 SEE ALSO

L<Coro>, L<Continuity>, L<Continuity::Mapper>, L<Squatting::Mapper>

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
