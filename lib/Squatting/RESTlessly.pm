package Squatting::RESTlessly;

use strict;
use warnings;
no  warnings 'redefine';

use Attribute::Handlers;
use Data::Dump 'dump';

sub session_queue : ATTR(CODE) {
  warn dump \@_;
}

1;
