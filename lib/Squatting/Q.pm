package Squatting::Q;

use strict;
use warnings;
no  warnings 'redefine';
no  warnings 'once';

use Attribute::Handlers;

sub Q : ATTR(CODE) {
  my ($package, $symbol, $coderef, $attr, $queue_suffix) = @_;
  $Squatting::Q{$coderef} = $queue_suffix;
}

1;

=head1 NAME

Squatting::Q - define a separate session queue for a controller

=head1 SYNOPSIS

  package App::Controllers;
  use base 'Squatting::Q'

  our @C = (
    C(
      Counter => '/count',
      get => sub : Q(count) {
        #          ^^^^^^^^ see this?
      },
    )
  );

=head1 DESCRIPTION

This module implements a subroutine attribute called C<Q> which takes an unquoted
string as a parameter.  "Q" is a mnemonic for "queue" and by defining a queue via
the subroutine attribute, you can allow your controller to execute in a separate
coroutine.

=head2 Why would I want to run in a separate coroutine?

My favorite answer is that running in a separate coroutine opens the door to
some COMET-friendly techniques.  Each coroutine has its own lexical scope, but
it is also aware of the global scope of the program as well.  This makes it
possible (and even easy) to coordinate between multiple sessions in a multiuser
web app.

(to be continued)

=head1 SEE ALSO

L<Attribute::Handlers>,
L<Coro>,
L<Squatting::Tutorial>

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
