package Squatting::On::CGI;

#use strict;
#no  strict 'refs';
#use warnings;
use CGI;
use HTTP::Response;

# p for private
my %p;
$p{init_cc} = sub {
  my ($c, $q)  = @_;
  my $cc       = $c->clone;
  $cc->env     = { %ENV };
  $cc->cookies = $p{c}->($ENV{HTTP_COOKIE});
  $cc->input   = $p{i}->($q);
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = { };
  $cc->status  = 200;
  $cc;
};

# \%input = i($q)  # Extract CGI parameters from a CGI object
$p{i} = sub {
  my $q = $_[0];
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

sub cgi {
  my ($app, $q) = @_;
  $ENV{PATH_INFO} ||= '/';
  $ENV{REQUEST_PATH} ||= do {
    my $script_name = $ENV{SCRIPT_NAME};
    $script_name =~ s{/$}{};
    $script_name . $ENV{PATH_INFO};
  };
  $ENV{REQUEST_URI} ||= do {
    ($ENV{QUERY_STRING})
      ? "$ENV{REQUEST_PATH}?$ENV{QUERY_STRING}"
      : $ENV{REQUEST_PATH};
  };
  eval {
    my ($c, $args) = &{$app."::D"}($ENV{REQUEST_PATH});
    my $cc = $p{init_cc}->($c, $q);
    my $content = $app->service($cc, @$args);
    my $response = HTTP::Response->new(
      $cc->status,
      undef,
      [ %{ $cc->{headers} } ],
      $content
    );
    print "Status: " . $response->as_string;
  };
  if ($@) {
    print $q->header(-status => 500);
    print "<pre>$@</pre>";
  }
}

1;

=head1 NAME

Squatting::On::CGI - if all else fails, you can still deploy on CGI

=head1 SYNOPSIS

Create an app.cgi to drive the Squatting app in a CGI environment.

  use App 'On::CGI';
  my $q = CGI->new;
  App->init;
  App->relocate('/cgi-bin/app.cgi');
  App->cgi($q);

=head1 DESCRIPTION

The purpose of this module is to allow Squatting apps to be used in a CGI
environment.  This is done by adding a C<cgi> method to the Squatting app that
knows how to "translate" between CGI and Squatting.  To use this module, pass
the string C<'On::CGI'> to the C<use> statement that loads your Squatting
app.

=head1 API

=head2 CGI -- The Lowest Common Demoninator

=head3 App->cgi($q)

Give the C<cgi> method a CGI object, and it will send the apps output to
STDOUT.

=cut
