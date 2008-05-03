package Squatting::RESTlessly;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';

use Attribute::Handlers;
use Data::Dump 'dump';

our %Q;

sub Q : ATTR(CODE) {
  my ($package, $symbol, $coderef, $attr, $queue_suffix) = @_;
  $Q{$coderef} = $queue_suffix;
}

1;
