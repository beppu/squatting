package Squatting::Q;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';
no  warnings 'once';

use Attribute::Handlers;

sub Q : ATTR(CODE) {
  my ($package, $symbol, $coderef, $attr, $queue_suffix) = @_;
  $Squatting::Q{$coderef} = $queue_suffix;
}

1;

__END__

=head1 NAME

Squatting::Q - define a separate session queue for a controller

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
