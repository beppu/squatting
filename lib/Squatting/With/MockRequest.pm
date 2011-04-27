package Squatting::With::MockRequest;
use common::sense;

# TODO - hook these in to the init
our %cookies;
our %state = (mock_request => 1);

sub mock_controller_init {
  my ($app, $cc, @args) = @_;
  $cc->{cr}          = {}; # TODO - provide a mock Continuity::Request
  $cc->{env}         = { REQUEST_PATH => &{"$app"."::Controllers::R"}($cc->name, @args) };
  $cc->{cookies}     = \%cookies;
  $cc->{input}       = {};
  $cc->{headers}     = {};
  $cc->{v}           = {};
  $cc->{state}       = \%state;
  $cc->{status}      = 200;
  $cc;
};

foreach my $method qw(get post put delete head) {
  *{$method} = sub {
    my ($app, $controller, @args) = @_;
    my $cc = ${$app."::Controllers::C"}{$controller}->clone;
    $app->mock_controller_init($cc, @args);
    $cc->env->{REQUEST_METHOD} = $method;
    if (ref($_[-1]) eq 'HASH') {
      $cc->input = pop @args;
    }
    my $content = $app->service($cc, @args);
    ($cc, $content);
  };
}

1;

__END__

=head1 NAME

Squatting::With::MockRequest - Mock HTTP helper methods mostly for the REPL

=head1 SYNOPSIS

  use App 'With::MockRequest';

  App->get(

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
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
