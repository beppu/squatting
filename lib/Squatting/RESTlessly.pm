package Squatting::RESTlessly;

use strict;
use warnings;
no  warnings 'redefine';

use Attribute::Handlers;

sub session_queue : ATTR(CODE) {
}

1;
