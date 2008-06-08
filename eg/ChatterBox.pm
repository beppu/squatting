package ChatterBox;
use base 'Squatting';

package ChatterBox::Controllers;
use selfvars;
use base 'Squatting::Q';
use Squatting ':controllers';

our @C = (
  C(
    Home => [ '/' ],
    get  => sub {
      $self->render('chatter_box');
    },
  ),
  C(
    Widget => [ '/@widget' ],
    get    => sub {
    },
  ),
  C(
    Event => [ '/@event' ],
    get   => sub : Q(chatter_box) {
    },
    post  => sub {
    },
  )
);

package ChatterBox::Views;
use selfvars;
use Squatting ':views';
use HTML::AsSubs;

# the ~literal pseudo-element -- don't entity escape this content
sub x {
  HTML::Element->new('~literal', text => $_[0])
}

# HTML::AsSubs forgot to implement span.
sub span {
  HTML::AsSubs::_elem('span', \@_);
}

our @V = (
  V(
    'html',
    _css => qq|
    |,
    widget => sub {
    },
    chatter_box => sub {
    },
  )
);

1;
