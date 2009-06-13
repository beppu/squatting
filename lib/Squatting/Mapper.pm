package Squatting::Mapper;

#use strict;
#no  strict 'refs'
#use warnings;
use base 'Continuity::Mapper';

sub get_session_id_from_hit {
  my ($self, $request) = @_;
  my $app = $self->{app};
  my $session_id = $self->SUPER::get_session_id_from_hit($request);
  my $path = $request->uri->path;
  my ($controller, $params) = &{$app."::D"}($path);
  my $method = lc $request->method;
  my $queue = $controller->{queue}->{$method};
  if (defined($queue)) {
    warn '$controller->{queue} has been deprecated in favor of $controller->{continuity}'."\n";
    warn "  perldoc Squatting::On::Continuity\n    for more details.\n";
    $session_id .= ".$app.$queue";
    $self->Continuity::debug(2, "    Session: got queue '$session_id'");
  }
  my $continuity = $controller->{continuity};
  my $ctrl_name = $controller->name;
  if (defined($continuity)) {
    $session_id .= ".$app.$ctrl_name.$path";
  }
  $session_id;
}

1;

=head1 NAME

Squatting::Mapper - map requests to session queues

=head1 DESCRIPTION

The purpose of this module is to be on the lookout for requests that should
be handled by L<Continuity>-based L<Squatting::Controller> objects.  This is
usually done by giving your controller a C<continuity> attribute and setting
it to a true value:

  C(
    Events => [ '/@events/(\d+)' ],

    get => sub {
      my ($self, $rand) = @_;
      my $cr = $self->cr;
      while (1) {
        # do stuff...
        $cr->next;
      }
    },

    continuity => 1,        # <--- causes Squatting::Mapper to notice
  )

=head1 SEE ALSO

L<Continuity::Mapper>

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
