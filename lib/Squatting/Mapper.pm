package Squatting::Mapper;

use strict;
use warnings;
use base 'Continuity::Mapper';
use Squatting::RESTlessly;

sub get_session_id_from_hit {
  my ($self, $request) = @_;
  my $session_id = $self->SUPER::get_session_id_from_hit($request);
  my ($controller, $params) = Squatting::D($request->uri->path);
  my $method  = lc $request->method;
  my $coderef = $controller->{$method};
  my $queue   = $Squatting::RESTlessly::Q{$coderef};
  if (defined($queue)) {
    $session_id .= ".$queue";
    $self->Continuity::debug(2, "    Session: got RESTless '$session_id'");
  }
  $session_id;
}

1;
