package HTTPAuth;
use base 'Squatting';

package HTTPAuth::Controllers;
use Squatting ':controllers';
use strict;
use warnings;

our @C = (
  C(
    Home => [ '/' ],
    get => sub {
      my ($self) = @_;
    }
  ),
  C(
    Secret => [ '/secret' ],
    get => sub {
      my ($self) = @_;
    }
  ),
  C(
    Himitsu => [ '/himitsu' ],
    get => sub {
      my ($self) = @_;
    }
  )
);

package HTTPAuth::Views;
use Squatting ':views';
use strict;
use warnings;
use HTML::AsSubs;

sub span { HTML::AsSubs::_elem('span', @_) }
sub x    { map { HTML::Element->new('~literal', text => $_) } @_ }

our @V = (
  V(
    'html',
    layout => sub {
      my ($self, $v, $content) = @_;
    },
    secret => sub {
      my ($self, $v) = @_;
    },
    himitsu => sub {
      my ($self, $v) = @_;
    },
  )
);

1;
