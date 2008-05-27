package Squatting::Mapper;

use strict;
use warnings;
use base 'Continuity::Mapper';

use Squatting::Q;

sub get_session_id_from_hit {
  my ($self, $request) = @_;
  my $session_id = $self->SUPER::get_session_id_from_hit($request);
  my ($controller, $params) = Squatting::D($request->uri->path);
  my $method  = lc $request->method;
  my $coderef = $controller->{$method};
  my $queue   = $Squatting::Q{$coderef};
  if (defined($queue)) {
    $session_id .= ".$queue";
    $self->Continuity::debug(2, "    Session: got queue '$session_id'");
  }
  $session_id;
}

1;

=head1 NAME

Squatting::Mapper - map requests to session queues

=head1 DESCRIPTION

You'll probably never use this module directly, but just so you know...
The purpose of this module is to be on the lookout for requests that should
route to controllers that have used the C<Q> subroutine attribute.
If it encounters such a request, it gives Continuity a $session_id with
the queue name appeneded to it.  This will cause Continuity to run this
request in a different session queue.

=head1 SEE ALSO

L<Squatting::Q>,
L<Continuity::Mapper>

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
