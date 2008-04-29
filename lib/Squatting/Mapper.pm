package Squatting::Mapper;

use strict;
use warnings;
use base 'Continuity::Mapper';

sub get_session_id_from_hit {
  my ($self, $request) = @_;
  my $session_id = $self->SUPER::get_session_id_from_hit($request);
  warn "SESSION_ID: $session_id";
  $session_id;
}

1;
