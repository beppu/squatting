package Squatting;

use strict;
no  strict 'refs';
use warnings;
use base 'Exporter';

use Continuity;
use Squatting::Mapper;

our $VERSION     = '0.12';
our @EXPORT_OK   = qw($app C R V);
our %EXPORT_TAGS = (
  controllers => [qw($app C R)],
  views       => [qw($app R V)]
);

# Kill the following package vars,
# and we might have a chance of working under mod_perl.
# However, I don't recommend exploring that path.
# Reverse proxies (like nginx, perlbal, apache 2's mod_proxy_balancer, etc.)
# are the way to go.
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
  my $C = \@{$app.'::Controllers::C'};
  my ($controller, @regex_captures);
  foreach $controller (@$C) {
    foreach (@{$controller->urls}) {
      if (@regex_captures = ($_[0] =~ qr{^$_$})) {
        pop @regex_captures if ($#+ == 0);
        return ($controller, \@regex_captures);
      }
    }
  }
  ($Squatting::Controller::r404, []);
}

# $url = R('Controller', @params, { cgi => vars })  # Routing function - TODO
sub R {
  '/'
}

# $view = V($name, %subs)  # Construct a Squatting::View
sub V {
  Squatting::View->new(@_);
}

# App->service($controller, @params)  # Override this method if you want to take actions before or after a request is handled.
sub service {
  my ($class, $controller, @params) = grep { defined } @_;
  my $method  = lc $controller->env->{REQUEST_METHOD};
  my $content;
  $I++;
  eval { $content = $controller->$method(@params) };
  warn "EXCEPTION: $@" if ($@);
  my $status = $controller->status;
  my $cookies = $controller->{set_cookies};
  warn sprintf('%5d ', $I), "[$status] $app->$method(@{[ join(', '=>map { \"'$_'\" } $controller->name, @params) ]})\n";
  $controller->headers('Set-Cookie' => join("; ", map {
    CGI::Cookie->new(-name => $_, %{$cookies->{$_}})
  } keys %$cookies)) if (%$cookies);
  if (my $cr_cookies = $controller->cr->cookies) {
    $cr_cookies =~ s/^Set-Cookie: //;
    $controller->headers('Set-Cookie' =>
      join("; ", grep { defined }
        ($controller->headers('Set-Cookie'), $cr_cookies)));
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

1

__END__

=head1 NAME

Squatting - a Camping-inspired Web Microframework for Perl

=head1 SYNOPSIS

A Basic Application

  {
    package App;
    use base 'Squatting';
    use App::Controllers;
    use App::Views;
  }

  {
    package App::Controllers;
    use Squatting ':controllers';

    # setup a list of controller objects using the C() function
    our @C = (
      C(
        Home => [ '/' ],
        get  => sub {
          my $self = shift;
          my $v = $self->v;
          $v->{title} = 'Hello, World!';
          $self->render('home');
          # $self->render('home', 'json');
        },
        post => sub { }
      ),
      C(
        Profile => [ '/~(\w+)/', '/~(\w+)\.(\w+)' ],
        get => sub {
          my ($self, $name, $format) = @_;
          $format ||= 'html';
          $self->v->{name} = $name;
          $self->render('profile', $format);
        },
        post => sub { }
      ),
    );
  }

  {
    package App::Views;
    use Squatting ':views';
    use JSON::XS;

    # setup a list of view objects using the V() function
    our @V = (
      V(
        'html',
        layout  => sub { my $v = shift; "<html><body>@_</body></html>" },
        home    => sub { my $v = shift; "<h1>$v->{title}</h1>" },
        profile => sub { my $v = shift; "<h1>I am $v->{name}.</h1>" },
      ),
      V(
        'json',
        _ => sub { encode_json($_[0]) },
      ),
    );
  }

Running Your App

  squatting App

=head1 DESCRIPTION

This is my attempt to bring the conciseness of Camping to Perl.

This is also my attempt to show that you don't need to have a huge
proliferation of classes to keep code well-organized.  (Prototype-based OO has
taught me this.)

=head1 AUTHOR

John BEPPU (beppu at cpan.org)

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
