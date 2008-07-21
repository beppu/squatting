package OpenID::Provider;

use base 'Squatting';
our %CONFIG;

package OpenID::Provider::Controllers;
use strict;
use warnings;
use Squatting ':controllers';

our @C = (
  C(
    Home => ['/'],
    get => sub {
      my ($self) = @_;
    },
  )
);

package OpenID::Provider::Views;

use strict;
use warnings;
use Squatting ':views';
use HTML::AsSubs;

our @V = (
  V(
    'html',
    layout => sub {
      my ($self, $v, $content) = @_;
    },
    home => sub {
      my ($self, $v) = @_;
    },
  )
);

1;
