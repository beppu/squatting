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

=head1 DESCRIPTION

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
