package Squatting;

use strict;
no  strict 'refs';
use warnings;
use base 'Exporter';

use Continuity;
use Squatting::Mapper;

use List::Util qw(first);
use URI::Escape;
use Carp;
use Data::Dump 'pp';

our $VERSION     = '0.31';
our @EXPORT_OK   = qw($app C R V);
our %EXPORT_TAGS = (
  controllers => [qw($app C R)],
  views       => [qw($app R V)]
);

# Kill the following package vars (especially $app),
# and we might have a chance of working under mod_perl.
our $app; 
our $I = 0;
our %Q;

require Squatting::Controller;
require Squatting::View;

# $controller = C($name => \@urls, %subs)  # Construct a Squatting::Controller
sub C {
  Squatting::Controller->new(@_);
}

# ($controller, \@regex_captures) = D($path)  # Return controller and captures for a path
sub D {
  no warnings 'once';
  my $url = uri_unescape($_[0]);
  my $C = \@{$app.'::Controllers::C'};
  my ($c, @regex_captures);
  for $c (@$C) {
    for (@{$c->urls}) {
      if (@regex_captures = ($url =~ qr{^$_$})) {
        pop @regex_captures if ($#+ == 0);
        return ($c, \@regex_captures);
      }
    }
  }
  ($Squatting::Controller::r404, []);
}

# $url = R('Controller', @params, { cgi => vars })  # Generate URLs with the routing function
sub R {
  my ($controller, @params) = @_;
  my $input;
  if (@params && ref($params[-1]) eq 'HASH') {
    $input = pop(@params);
  }
  my $c = ${$app."::Controllers::C"}{$controller};
  croak "$controller controller not found" unless $c;
  my $arity = @params;
  my $pattern = first { my @m = /\(.*?\)/g; $arity == @m } @{$c->urls};
  croak "couldn't find a matching URL pattern" unless $pattern;
  while ($pattern =~ /\(.*?\)/) {
    $pattern =~ s{\(.*?\)}{uri_escape(+shift(@params), "^A-Za-z0-9\-_.!~*’()/")}e;
  }
  if ($input) {
    $pattern .= "?".  join('&' => 
      map { 
        my $k = $_;
        ref($input->{$_}) eq 'ARRAY'
          ? map { "$k=".uri_escape($_) } @{$input->{$_}}
          : "$_=".uri_escape($input->{$_})
      } keys %$input);
  }
  $pattern;
}

# $view = V($name, %subs)  # shortcut for constructing a Squatting::View
sub V {
  Squatting::View->new(@_);
}

# App->service($controller, @params)  # Override this method if you want to take actions before or after a request is handled.
sub service {
  my ($class, $c, @params) = grep { defined } @_;
  my $method  = lc $c->env->{REQUEST_METHOD};
  my $content;
  $I++;
  eval { $content = $c->$method(@params) };
  warn "EXCEPTION: $@" if ($@);
  my $s = $c->status;
  my $cookies = $c->cookies;
  my $ppi = (%{$c->input}) 
    ? ', ' . pp($c->input) 
    : '';
  #
  warn sprintf('%5d ', $I), "[$s] $app->$method(@{[ join(', '=>map { \"'$_'\" } $c->name, @params) ]}$ppi)\n";
  #
  $c->headers->{'Set-Cookie'} = join("; ",
    map { CGI::Cookie->new( -name => $_, %{$cookies->{$_}} ) }
      grep { ref $cookies->{$_} eq 'HASH' }
        keys %$cookies) if (%$cookies);
  if (my $cr_cookies = $c->cr->cookies) {
    $cr_cookies =~ s/^Set-Cookie: //;
    $c->headers->{'Set-Cookie'} = join("; ",
      grep { defined } ($c->headers->{'Set-Cookie'}, $cr_cookies));
  }
  return $content;
}

# App->init  # Initialize $app
sub init {
  $app = shift;
  %{$app."::Controllers::C"} = map { $_->name => $_ }
  @{$app."::Controllers::C"};
  %{$app."::Views::V"} = map { $_->name => $_ }
  @{$app."::Views::V"};
}

# App->go(%opts)  # Start the server.
sub go {
  $app = shift;
  $app->init;
  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port     => 4234,
    mapper   => Squatting::Mapper->new(
      callback => sub {
        my $cr = shift;
        my ($c, $p)  = D($cr->uri->path);
        my $cc       = $c->clone->init($cr);
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

=head1 NAME

Squatting - A Camping-inspired Web Microframework for Perl

=head1 SYNOPSIS

Running an App:

  $ squatting App
  Please contact me at: http://localhost:4234/

Check out our ASCII art logo:

  $ squatting --logo

What a basic App looks like:

  # STEP 1 => Subclass Squatting
  {
    package App;
    use base 'Squatting';
    #use App::Controllers;
    #use App::Views;
  }

  # STEP 2 => Create a Controllers package
  {
    package App::Controllers;
    use Squatting ':controllers';

    # Setup a list of controller objects using the C() function.
    our @C = (
      C(
        Home => [ '/' ],
        get  => sub {
          my ($self) = @_;
          my $v = $self->v;
          $v->{title} = 'Hello, World!';
          $self->render('home');
        },
        post => sub { }
      ),
    );
  }

  # STEP 3 => Create a Views package
  {
    package App::Views;
    use Squatting ':views';

    # Setup a list of view objects using the V() function.
    our @V = (
      V(
        'html',
        layout  => sub {
          my ($self, $v, $content) = @_;
          "<html><body>$content</body></html>"
        },
        home    => sub {
          my ($self, $v) = @_;
          "<h1>$v->{title}</h1>"
        },
      ),
    );
  }

  # Models?  The whole world is your model.  ;-)
  # - I've always been ambivalent about defining policy here.
  # - Use whatever works for you.

=head1 DESCRIPTION

Squatting is a web microframework based on Camping
that uses L<Continuity> as its foundation.

=head2 What does this mean?

=over 4

=item B<Concise API>

_why did a really good job designing Camping's API, so I copied quite a bit
of the feel of Camping for Squatting.

=item B<Tiny Codebase>

Right now, it's around 6.6K of actual code (after minifying), but it can
definitely get smaller.  Also, the number of Perl module dependencies has been
kept down to a minimum.

=item B<RESTful Controllers By Default>

Controllers are objects (not classes) that are made to look like HTTP
resources.  Thus, they respond to methods like get(), post(), put(), and
delete().

=item B<RESTless Controllers Are Possible (thanks to Continuity)>

Stateful continuation-based code can be surprisingly useful (especially for
COMET), so we try to make RESTless controllers easy to express as well.

=item B<Views Are ...Different>

The View API feels like Camping, but Squatting allows multiple views to coexist
(kinda like Catalyst (but not quite)).

=item B<Minimal Policy>

You may use any templating system you want, and you may use any ORM(*) you want.
We only have a few rules on how the controller code and the view code should be
organized, but beyond that, you are free.

=back

* Regarding ORMs, the nature of Continuity makes it somewhat DBI-unfriendly, so
this may be a deal-breaker for many of you.  However, I look at this as an
opportunity to try novel storage systems like CouchDB, instead.  With the high
level of concurrency that Squatting can support (thanks to Continuity) we are
probably better off this way.

=head1 API

=head2 Use as a Base Class for Squatting Applications

  package App;
  use base 'Squatting';
  1;

=head3 App->service($controller, @args)

Every time an HTTP request comes in, this method is called with a controller
object and a list of arguments.  The controller will then be invoked with the
HTTP method that was requested (like GET or POST), and it will return the
content of the response as a string.

B<NOTE>:  If you want to do anything before, after, or around an HTTP request,
this is the method you should override in your subclass.

=head3 App->init

This method takes no parameters and initializes some internal variables.

=head3 App->go(%options)

This method calls init and then starts a Continuity-based web server.  The %options
are passed straight through to Continuity.

=head2 Use as a Helper for Controllers

  package App::Controllers;
  use Squatting ':controllers';

=head3 C($name => \@urls, %methods)

This is a shortcut for:

  Squatting::Controller->new(@_);

=head3 R($name, @args, [ \%params ])

R() is a URL generation function that takes a controller name and a list of arguments.
You may also pass in a hashref representing CGI variables as the very last parameter
to this function.

B<Example>:  Given the following controllers, R() would respond like this.

  # Example Controllers
  C(Home    => [ '/' ]);
  C(Profile => [ '/~(\w+)', '/~(\w+)\.(\w+)' ]);

  # Generated URLs
  R('Home')                             # "/"
  R('Home', { foo => 1, bar => 2})      # "/?foo=1&bar=2"
  R('Profile', 'larry')                 # "/~larry"
  R('Profile', 'larry', 'json')         # "/~larry.json"

=head2 Use as a Helper for Views

  package App::Controllers;
  use Squatting ':views';

=head3 V($name, %methods)

This is a shortcut for:

  Squatting::View->new(@_);

=head3 R($name, @args, [ \%params ])

This is the same R() function that the controllers get access to.

=head1 SEE ALSO

L<Squatting::Controller>, L<Squatting::View>, L<Squatting::Mapper>, L<Squatting::Q>

=head2 Squatting Source Code

The source code is short and it has some useful comments in it, so this might
be all you need to get going.  There are also some examples in the F<eg/>
directory.

L<http://github.com/beppu/squatting/tree/master>

=head2 Bavl Source Code

We're going to throw Squatting into the metaphorical deep end by using it to
implement the towr.of.bavl.org.  If you're looking for an example of how to use
Squatting for an ambitious project, look at the Bavl code.

L<http://github.com/beppu/bavl/tree/master>

=head2 Continuity and Coro

When you want to start dabbling with RESTless controllers, it would serve
you well to understand how Continuity and Coro work.  I recommend reading the
POD for the following Perl modules:

L<Continuity>,
L<Coro>,
L<Coro::Event>,
L<Event>.

Also, check out the Continuity web site.

L<http://continuity.tlt42.org/>

=head2 Camping

Squatting is the spiritual descendant of Camping, so studying the Camping API
will indirectly teach you much of the Squatting API.

L<http://code.whytheluckystiff.net/camping/>

=head2 Prototype-based OO

There were a lot of obscure Ruby idioms in Camping that were damn near
impossible to directly translate into Perl.  I got around this by resorting to
techniques that are reminiscent of prototype-based OO.  (That's why controllers
and views are objects instead of classes.)

=head3 Prototypes == Grand Unified Theory of Objects

I've been coding a lot of JavaScript these days, and it has definitely
influenced my programming style.  I've come to love the simplicity of
prototype-based OO, and I think it's a damned shame that they're introducing
concepts like 'class' in the next version of JavaScript.  It's like they missed
the point of prototype-based OO.

If you're going to add anything to JavaScript, make the prototype side of it
stronger.  Look to languages like Io, and make it easier to clone objects and
manipulate an object's prototype chain.  The beauty of prototypes is that this
one concept can be used to unify objects, classes, and namespaces.  Look at Io
if you don't believe me.

L<http://iolanguage.com/>

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 John BEPPU E<lt>beppu@cpan.orgE<gt>.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: f ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: f ***
# End: ***
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
