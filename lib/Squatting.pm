package Squatting;

use strict;
no  strict 'refs';
use warnings;
use base 'Exporter';
use Continuity;
use Squatting::Mapper;
use Data::Dump qw(dump);

our $VERSION     = '0.01';
our @EXPORT_OK   = qw($app C R V);
our %EXPORT_TAGS = (
  controllers => [qw($app C R)],
  views       => [qw($app R V)]
);

# Kill the following package vars,
# and we might have a chance of working under mod_perl.
our $app;
our $I = 1;
our %Q;

require Squatting::Controller;
require Squatting::View;

# $controller = C($name => \@urls, %subs)  # Construct a Squatting::Controller
sub C {
  Squatting::Controller->new(@_);
}

# ($controller, \@regex_captures) = D($path)  # Return controller and captures for a path
sub D {
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

# $url = R(Controller, params..., { cgi => vars }) TODO
sub R {
  '/'
}

# $view = V($name, %subs)  # Construct a Squatting::View
sub V {
  Squatting::View->new(@_);
}

# Override this method if you want to take actions before or after a request is handled.
sub service {
  my ($class, $controller, @params) = grep { defined } @_;
  my $method  = lc $controller->env->{REQUEST_METHOD};
  my $content;
  eval { $content = $controller->$method(@params) };
  warn "EXCEPTION: $@" if ($@);
  my $status = $controller->status;
  my $cookies = $controller->{set_cookies};
  warn sprintf('%5d ', $I++), "[$status] @{[$controller->name]}(@{[ join(', '=>@params) ]})->$method";
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

# Initialize $app
sub init {
  $app = shift;
  %{$app."::Controllers::C"} = map { $_->name => $_ } 
  @{$app."::Controllers::C"};
  %{$app."::Views::V"} = map { $_->name => $_ }
  @{$app."::Views::V"};
}

# Start the server.
sub go {
  $app = shift;
  $app->init;
  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port     => 4234,
    mapper   => Squatting::Mapper->new(
      callback => sub {
        my $cr = shift;
        my ($c, $p) = D($cr->uri->path);
        my $cc = $c->clone->init($cr);
        my $content = $app->service($cc, @$p);
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

  {
    package Bavl;
    use base 'Squatting';
  }

  {
    package Bavl::Controllers;
    use Squatting ':controllers';

    our @C = (
      C(
        Home => [ '/' ],
        get  => sub {
          my $self = shift;
          my $v = $self->v;
          $v->{title} = loc('Hello, World!');
          $self->render('home');
          # $self->render('home', 'json');
        },
      ),
    );
  }

  {
    package Bavl::Views;
    use Squatting ':views';
    use JSON::XS;

    our @V = (
      V(
        'html',
        layout => sub { my $v = shift; "<html><body>@_</body></html>" },
        home   => sub { my $v = shift; "<h1>$v->{title}</h1>" },
        login  => sub { },
        search => sub { }
      ),
      V(
        'json',
        _ => sub { encode_json($_[0]) },
      ),
    );
  }

=head1 DESCRIPTION

This is beppu's attempt to bring the conciseness of Camping to Perl.

This is also my attempt to show that you don't need to have a huge
proliferation of classes to keep code well-organized.  (JavaScript and
prototype-based OO has taught me this.)

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
