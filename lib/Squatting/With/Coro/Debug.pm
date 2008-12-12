package Squatting::With::Coro::Debug;

#use strict;
#use warnings;
use Coro::Debug;

sub init {
  my $app    = shift;
  my $config = \%{$app.'::CONFIG'};
  my $path   = $config->{'with.coro.debug.unix_domain_socket'} 
    || '/tmp/squatting.with.coro.debug';
  our $debug = Coro::Debug->new_unix_server($path);
  $app->next::method;
}

1;

__END__

=head1 NAME

Squatting::With::Coro::Debug - inspect running Squatting apps with Coro::Debug

=head1 SYNOPSIS

From the command line:

  squatting --module With::Coro::Debug App

From a script:

  use App qw(On::Continuity With::Coro::Debug);
  App->init;
  App->continue();

Connect to Coro::Debug in another terminal

  socat readline unix:/tmp/squatting.with.coro.debug

A Coro::Debug session looks like this:

  > ps
                 PID SC  RSS USES Description              Where
           142161516 RC 245k   23 [main::]                 [Event.pm:164]
           142188912 -- 1404    4 [coro manager]           [Coro.pm:358]
           142189128 N-   84    0 [unblock_sub scheduler]  -
           142455240 N-   84    0 [Event idle process]     -
           146549540 -- 7340   14                          [HttpDaemon.pm:426]
           146549792 -- 2088    5                          [Continuity.pm:436]
           146552468 UC 3344    6 [Coro::Debug session]    [Coro.pm:257]

=head1 DESCRIPTION

Using this module in conjunction with a Squatting app that's running on top of
Continuity will provide you with a L<Coro::Debug> server that you can connect
to using tools like C<socat>.  This will let you inspect the state of your
Squatting app while its running.

=head1 CONFIG

=over 4

=item with.coro.debug.unix_domain_socket

This should be a string that represents the path of the Unix domain socket
that Coro::Debug will use.  If this option is not set, the default value
is F</tmp/squatting.with.coro.debug>.

B<Example>

  $CONFIG{'with.coro.debug.unix_domain_socket'} = '/tmp/coro-debug-socket';

=back

=head1 SEE ALSO

=head2 Perl Modules

L<Coro>,
L<Coro::Debug>,
L<Continuity>,
L<Squatting::On::Continuity>

=head2 socat

L<http://www.dest-unreach.org/socat/>

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
