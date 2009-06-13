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
  my $controller_name = $controller->name;
  if (defined($continuity)) {
    $session_id .= ".$app.$controller_name.$path";
  }
  $session_id;
}

1;

=head1 NAME

Squatting::Mapper - map requests to session queues

=head1 DESCRIPTION

The purpose of this module is to be on the lookout for requests that should get
special treatment by L<Continuity>.  This is usually done by giving your
controller a C<continuity> attribute and setting it to a true value:

  C(
    Events => [ '/@events/(\d+)' ],

    get => sub {
      my ($self, $rand) = @_;
      my $cr = $self->cr;
      while (1) {           # <--- COMET event loops typically loop forever
        # broadcasting relevant events
        # to long-polling HTTP requests
        # as they come in...
        $cr->next;
      }
    },

    continuity => 1,        # <--- causes Squatting::Mapper to notice
  )

When it sees that C<continuity> is true, the request will be given a
session id based on: $cookie_session + $app_name + $controller_name + $path.
Normally, it's just $cookie_session, but when you get these extra pieces
added to your session id, that tells Continuity that you want to have a
separate coroutine for this request.

The primary intended use for handling requests in a separate coroutine is to
facilitate COMET event loops.  When a user visits a COMET-enabled site, there
will be some JavaScript that starts a long-polling HTTP request.  On the
server-side, the long-polling handler will typically have an infinite loop in
it, so it needs to sit off in its own coroutine so that it doesn't affect the
coroutine that is handling the normal, RESTful requests.

If the user decides to open multiple-tabs to the same COMET-enabled site,
each of those tabs needs to be differentiated on the server-side as well.
That's when it becomes useful to stick something random in the path.
Notice in the example that the path regex is '/@events/(\d+)'.

It would be the job of the JavaScript to append a random string of digits to
the end of an '/@events/(\d+)' URL before starting the long-poll request.
That'll let Squatting::Mapper give each tab its own coroutine as well.

=head1 SEE ALSO

L<Squatting::On::Continuity>, L<Continuity::Mapper>

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
