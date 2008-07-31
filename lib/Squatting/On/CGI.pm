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
      HTTP::Status::status_message($cc->status),
      [ %{ $cc->{headers} } ],
      $content
    );
    print $response->as_string;
  };
  if ($@) {
    print $q->header;
    print "<pre>$@</pre>";
  }
}

1;

=head1 NAME

Squatting::On::CGI - if all else fails, you can still deploy on CGI

=head1 SYNOPSIS

Create an app.cgi

  use App 'On::CGI';
  my $q = CGI->new;
  App->init;
  App->relocate('/app.cgi');
  App->cgi($q);

=head1 DESCRIPTION

If all else fails, you can still deploy on good old CGI.

=head1 API

=head2 CGI -- The Lowest Common Demoninator

=head3 App->cgi($q)

Give the C<cgi> method a CGI object, and it'll take care of everything else.

=cut
