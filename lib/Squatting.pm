package Squatting;

use strict;
no  strict 'refs';
use warnings;
use base 'Exporter';
use Continuity;
use Squatting::Mapper;
use CGI::Simple;
use CGI::Simple::Cookie;
use Data::Dump qw(dump);

our $VERSION     = '0.01';
our @EXPORT_OK   = qw(
  C $cr %cookies cookies %input $headers headers $status $s R redirect render
);
our %EXPORT_TAGS = (
  controllers => [qw(C $cr %cookies cookies %input $headers headers $status $s R redirect render)],
  views       => [qw(%cookies %input $s R)]
);

our $app;
our $cr;
our %input;
our %cookies; #incoming
our $cookies; #outgoing
our $headers;
our $status;
our $s;

require Squatting::Controller;

# controller constructing function
sub C {
  ref($_[0]) ? $_[0] : Squatting::Controller->new(@_);
}

# ($controller, \@regex_captures) = D($path)  # controller and captures for a path
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

# $url = R(Controller, params..., { cgi => vars })
sub R {
}

# $content = render($template, $view) TODO
sub render { 
  my ($t, $v) = @_;
}

# redirect($url, $status_code)
sub redirect {
  my ($l, $s) = @_;
  headers('Location') = $l || '/';
  $status             = $s || 302;
}

# %ENV = e($http_request)  # Get request headers from HTTP::Request.
sub e {
  my $r = shift;
  my %env;
  my $uri = $r->uri;
  $env{QUERY_STRING}   = $uri->query;
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

# cookies($name) = { -value => 'chocolate_chip' }  # Set outgoing cookies.
sub cookies : lvalue { 
  $cookies->{$_[0]};
}

# headers($name) = "value"  # Set an outgoing header.
sub headers : lvalue {
  $headers->{$_[0]};
}

# Override this method if you want to take actions before or after a request is handled.
sub service {
  my ($class, $controller, @params) = @_;
  my $method  = lc $ENV{REQUEST_METHOD};
  my $content;
  eval {
    $content = $controller->$method(@params);
  };
  warn "@{[$controller->name]}->$method => $content\n";
  headers('Set-Cookie') = join("; ", map { 
    CGI::Simple::Cookie->new(-name => $_, %{$cookies->{$_}}) 
  } keys %$cookies) if (%$cookies);
  return $content;
}

# Start the server.
sub go {
  no warnings; # life can be surprising
  $app = shift;

  # Putting a RESTful face on Continuity since 2008.
  Continuity->new(
    port     => 4234,
    mapper   => Squatting::Mapper->new(
      callback => sub {
        $cr = shift;
        local %ENV   = e($cr->http_request);
        %cookies     = c($ENV{HTTP_COOKIE});
        $cookies     = {};
        $headers     = {};
        my ($c, $p)  = D($ENV{REQUEST_PATH});
        %input       = i($cr);
        $status      = 200;
        my $content  = $app->service($c, @$p);
        my $response = HTTP::Response->new($status, 'orz', [%$headers], $content);
        $cr->conn->send_response($response);
        $cr->end_request;
      }
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
      'HTML',
      home   => sub { "<h1>" . $s->{title} . "</h1>" },
      login  => sub { },
      search => sub { }
    );

    V(
      'JSON',
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
