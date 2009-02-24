package Squatting::On::MP20;

use strict;
use warnings;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Const -compile => qw(OK);
use CGI::Cookie;
use Squatting::H;

# adapt Apache::Log's interface to Squatting::Log's interface
our $log = Squatting::H->new({
  _log  => undef,
  debug => sub {
    my ($self, @messages) = @_;
    $self->_log->debug(@messages);
  },
  info => sub {
    my ($self, @messages) = @_;
    $self->_log->info(@messages);
  },
  warn => sub {
    my ($self, @messages) = @_;
    $self->_log->warn(@messages);
  },
  error => sub {
    my ($self, @messages) = @_;
    $self->_log->error(@messages);
  },
  fatal => sub {
    my ($self, @messages) = @_;
    $self->_log->emerg(@messages);
  },
});

# p for private
my %p;
$p{init_cc} = sub {
  my ($c, $r)  = @_;
  my $cc       = $c->clone;
  $cc->env     = $p{e}->($r->headers_in);
  $cc->cookies = $p{c}->($ENV{HTTP_COOKIE});
  $cc->input   = $p{i}->($r->args);
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = { };
  $cc->status  = 200;
  $cc->log     = $log;
  $log->_log($r->log);
  $cc;
};

# \%input = $p{i}->($query_string)  # Extract CGI parameters from QUERY_STRING
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

# \%cookies = $p{c}->($cookie_header)  # Parse Cookie header(s).
$p{c} = sub {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
};

# \%env = $p{e}->($r->headers_in)  # Extract incoming HTTP headers from $r->headers_in
$p{e} = sub {
  my ($hd) = @_;
  my %env = %ENV;
  while (my ($k, $v) = each(%$hd)) {
    my $key = uc $k; $key =~ s/-/_/g;
    $env{$key} = $v;
  }
  \%env;
};

sub mp20 {
  no strict 'refs';
  my ($app, $r) = @_;
  my ($c,   $p) = &{ $app . "::D" }($r->uri);
  my $cc = $p{init_cc}->($c, $r);
  my $content = $app->service($cc, @$p);
  my $headers = ($cc->status >= 200 && $cc->status < 300)
    ? $r->headers_out
    : $r->err_headers_out;
  while (my($h, $v) = each(%{$cc->headers})) {
    if ($h =~ /Content-Type/i) {
      $r->content_type($v); # XXX - Why did I even have to do this????!!@$
    } else {
      $headers->{$h} = $v;
    }
  }
  $r->status($cc->status);
  $r->set_content_length(length($content));
  $r->print($content);
  Apache2::Const::OK;
}

1;

=head1 NAME

Squatting::On::MP20 - mod_perl 2.0 support for Squatting

=head1 SYNOPSIS

Load

  <Perl>
    use App 'On::MP20';
    App->init
  </Perl>

Setup handler

  <Location />
    SetHandler perl-script
    PerlHandler App->mp20
  </Location>

VirtualHost Configuration Example

  ...

=head1 DESCRIPTION

=head1 API

=head2 Something Clever

=head3 App->mp20

=head1 SEE ALSO

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
