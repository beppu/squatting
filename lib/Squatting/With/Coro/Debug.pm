package Squatting::With::Coro::Debug;

use strict;
use warnings;

sub init {
  my ($app)  = shift;
  my $config = \%{$app.'::CONFIG'};
  my $path   = $config->{'with.coro.debug.unix_domain_socket'} 
    || '/tmp/squatting.with.coro.debug';
  our $server = Coro::Debug->new_unix_server($path);
  $app->next::method(@_);
}

1;
