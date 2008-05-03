package Squatting::Q;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';

use Attribute::Handlers;

sub Q : ATTR(CODE) {
  my ($package, $symbol, $coderef, $attr, $queue_suffix) = @_;
  $Squatting::Q{$coderef} = $queue_suffix;
}

1;
