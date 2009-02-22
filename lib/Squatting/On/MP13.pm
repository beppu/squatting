package Squatting::On::MP13;

use strict;
use warnings;
use Apache;
use Apache::Log;
use CGI::Cookie;
use Apache::Constants ':common';
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
  $cc->env     = { %ENV };
  $cc->cookies = $p{c}->($ENV{HTTP_COOKIE});
  $cc->input   = { $r->args };
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = { };
  $cc->status  = 200;
  $cc->log     = $log;
  $log->_log($r->log);
  $cc;
};

# \%cookies = $p{c}->($cookie_header)  # Parse Cookie header(s).
$p{c} = sub {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
};

sub mp13($$) {
  no strict 'refs';
  my ($app, $r) = @_;
  my ($c,   $p) = &{ $app . "::D" }($r->uri);
  my $cc = $p{init_cc}->($c, $r);
  my $content = $app->service($cc, @$p);
  while (my($header, $value) = each(%{$cc->headers})) {
    $r->header_out($header, $value);
  }
  $r->status($cc->status);
  $r->print($content);
  OK;
}

sub init {
  no strict 'refs';
  no warnings 'redefine';
  my ($app) = @_;
  *{ $app . "::handler" } = sub {
    my ($r) = @_;
    $app->mp13($r);
  };
  $app->next::method;
}

1;

__END__

=head1 NAME

Squatting::On::MP13 - a handler for Apache 1.3's mod_perl

=head1 SYNOPSIS

First, load the App + Squatting::On::MP13:

  <Perl>
    use App 'On::MP13';
    App->init;
  </Perl>

Then, setup a handler in your Apache config:

  <Location />
    SetHandler  perl-script
    PerlHandler App
  </Location>

Alternatively, if your mod_perl has L<method handler|mod_perl_method_handlers>
support, you can say:

  <Location />
    SetHandler  perl-script
    PerlHandler App->mp13
  </Location>

VirtualHost configuration using L<Pod::Server> as an example:

  <VirtualHost *:80>
    ServerName   podserver.mydomain.org
    DocumentRoot /www/podserver.mydomain.org
    ErrorLog     logs/podserver.mydomain.org-error_log
    CustomLog    logs/podserver.mydomain.org-access_log common
    <Perl>
      use Pod::Server 'On::MP13';
      Pod::Server->init;
    </Perl>
    <Location />
      SetHandler  perl-script
      PerlHandler Pod::Server
    </Location>
  </VirtualHost>

=head1 DESCRIPTION

The purpose of this module is to add an C<mp13> method to your app that can be
used as a mod_perl method handler.  It also adds a conventional mod_perl handler
so that Squatting apps can be deployed on mod_perl installations that don't
have method handler support built in.  To use this module, pass the string
C<'On::MP13'> to the C<use> statement that loads your Squatting app.  Also,
make sure you've configured your Apache to use C<App-E<gt>mp13> as the handler.

=head1 API

=head2 They should have stopped at Apache 1.3.37.

=head3 App->mp13($r)

This method takes an L<Apache> request object, and translates the request into
terms that Squatting understands.  Then, after your app has handled the request,
it will send out an HTTP response via mod_perl.

=head3 App::handler($r)

Unfortunately, it is common for mod_perl to not have method handler support
compiled in, so a more conventional mod_perl handler is also provided.  This
just calls C<App-E<gt>mp13($r)>.

(Note that this sub is added directly to the App that loaded
Squatting::On::MP13.  It's C<App::handler> and NOT C<App-E<gt>handler>.)

=head1 SEE ALSO

L<Squatting::On::MP20>

L<Apache>, L<mod_perl>, L<mod_perl_method_handlers>

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
