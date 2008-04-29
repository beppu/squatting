package Squatting::RESTlessly;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';

use Attribute::Handlers;
use Data::Dump 'dump';

our %Q;

sub session_queue : ATTR(CODE) {
  my ($package, $symbol, $coderef, $attr, $queue_suffix) = @_;
  warn dump \@_;
  $Q{$coderef} = $queue_suffix;
}

1;
