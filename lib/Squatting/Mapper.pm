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

__END__

=head1 NAME

Squatting::Mapper - map requests to session queues

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
