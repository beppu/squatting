package Squatting;

use strict;
no  strict 'refs';
use warnings;
use base 'Exporter';
use Continuity;
use Squatting::Mapper;
use Data::Dump qw(dump);

our $VERSION     = '0.01';
our @EXPORT_OK   = qw(C R V);
our %EXPORT_TAGS = (
  controllers => [qw(C R)],
  views       => [qw(R V)]
);

require Squatting::Controller;
require Squatting::View;

our $app;

# $controller = C($name => \@urls, %subs)  # Construct a Squatting::Controller
sub C {
  my ($app) = caller;
  $app =~ s/::Controllers$//;
  Squatting::Controller->new(app => $app, @_);
}

# ($controller, \@regex_captures) = D($path)  # Return controller and captures for a path
sub D {
  my $C = \@{$app.'::Controllers::C'};
  my ($controller, @regex_captures);
  foreach $controller (@$C) {
    foreach (@{$controller->urls}) {
      if (@regex_captures = ($_[0] =~ qr{^$_$})) {
        return ($controller, \@regex_captures);
      }
    }
  }
  ($Squatting::Controller::r404, []);
}

# $url = R(Controller, params..., { cgi => vars }) TODO
sub R {
}

# $view = V($name, %subs)  # Construct a Squatting::View
sub V {
  Squatting::View->new(@_);
}

# %ENV = e($http_request)  # Get request headers from HTTP::Request.
sub e {
  my $r = shift;
  my %env;
  my $uri = $r->uri;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = $uri->path;
  $env{REQUEST_METHOD} = $r->method;
  $r->scan(sub{
    my ($header, $value) = @_;
    my $key = uc $header;
    $key =~ s/-/_/g;
    $key = "HTTP_$key";
    $env{$key} = $value;
  });
  %env;
}

# %input = i($cr)  # Extract CGI parameters from Continuity::Request.
sub i {
  $_[0]->params;
}

# %cookies = c($cookie_header)  # Parse Cookie header(s). TODO
sub c {
}

# Override this method if you want to take actions before or after a request is handled.
sub service {
  my ($class, $controller, @params) = grep { defined } @_;
  my $method  = lc $ENV{REQUEST_METHOD};
  my $content;
  eval { $content = $controller->$method(@params) };
  warn "EXCEPTION: $@" if ($@);
  warn "[$status] @{[$controller->name]}(@{[ join(', '=>@params) ]})->$method => @{[dump($v)]}";
  headers('Set-Cookie') = join(";", map { 
    CGI::Cookie->new(-name => $_, %{$cookies->{$_}}) 
  } keys %$cookies) if (%$cookies);
  return $content;
}

# Start the server.
sub go {
  $app = shift;
  %{$app."::Views::V"} = map { $_->name => $_ }
  @{$app."::Views::V"};
  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port     => 4234,
    mapper   => Squatting::Mapper->new(
      callback => sub {
        $cr = shift;
        local %ENV   = e($cr->http_request);
        my ($c, $p)  = D($ENV{REQUEST_PATH});
        %cookies     = c($ENV{HTTP_COOKIE});
        %input       = i($cr);
        $cookies     = {};
        $headers     = {};
        $state       = {};
        $v           = {};
        $status      = 200;
        my $content  = $app->service($c, @$p);
        my $response = HTTP::Response->new($status, 'orz', [%$headers], $content);
        #$cr->conn->send_basic_header;
        #$cr->print($content);
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

Squatting - a web microframework for Perl that was inspired by Camping

=head1 SYNOPSIS

  {
    package Bavl;
    use base 'Squatting';
    sub authenticate { 1 }
    Bavl->go();
  }

  {
    package Bavl::Controllers;
    use Squatting ':controllers';

    C(
      Home => [ '/' ],
      get  => sub {
        $s->{title} = loc('Hello, World!');
        render 'home'
      },
    );

    C(
      Login => [ '/log/(in|out)' ],
      get   => sub {
        my $in_or_out = shift;
        render 'login'
      },
      post  => sub {
        my $in_or_out = shift;
        my $username = $input->{username};
        my $password = $input->{password};
        if (Bavl->authenticate($username, $password)) {
          $s->{logged_in} = 1;
          redirect R('Home');
        } else {
          redirect R('Login');
        }
      }
    );
  }

  {
    package Bavl::Views;
    use Squatting ':view';

    V(
      'html',
      home   => sub { "<h1>" . $s->{title} . "</h1>" },
      login  => sub { },
      search => sub { }
    );

    V(
      'json',
      search => sub { to_json($s) },
    )
  }


=head1 DESCRIPTION

This is beppu's attempt to bring the conciseness of Camping to Perl.

This is also my attempt to show that you don't need to have a huge proliferation
of classes to keep code well-organized.  (JavaScript and prototype-based OO has taught
me this.)

=head1 AUTHOR

John BEPPU (beppu at cpan.org)

=cut
