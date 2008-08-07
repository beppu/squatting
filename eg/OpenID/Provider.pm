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
      $self->render('home');
    },
  )
);

package OpenID::Provider::Views;

use strict;
use warnings;
use Squatting ':views';
use HTML::AsSubs;

# the ~literal pseudo-element -- don't entity escape this content
sub x {
  HTML::Element->new('~literal', text => $_[0])
}

our @V = (
  V(
    'html',
    layout => sub {
      my ($self, $v, $content) = @_;
      html(
        head(
          title('OpenID Provider')
        ),
        body(
          h1('OpenID Provider'),
          x($content)
        ),
      )->as_HTML;
    },
    home => sub {
      my ($self, $v) = @_;
      h2("TODO - Implement OpenID::Provider")->as_HTML;
    },
  )
);

1;
