package OpenID::Consumer;

use base 'Squatting';
our %CONFIG;

package OpenID::Consumer::Controllers;
use strict;
use warnings;
use Squatting ':controllers';
use Net::OpenID::Consumer;
use LWPx::ParanoidAgent;
use Cache::File;

our @C = (

  C(
    Home => ['/'],
    get => sub {
      my ($self) = @_;
      $self->render('home');
    },
  ),

  # The Conventional Way
  C(
    Login => [ '/login' ],
    get => sub {
      my ($self) = @_;
      my $csr = $self->{csr}->($self);
    },
    post => sub {
      my ($self) = @_;
      my $csr = $self->{csr}->($self);
    },
    csr => sub {
      my ($self) = @_;
      return Net::OpenID::Consumer->new(
        ua    => LWPx::ParanoidAgent->new,
        cache => Cache::File->new(cache_root => '/tmp/openid-consumer-cache'),
        args  => $self->input,
        consumer_secret => '...',
        required_root   => 'http://work:4234/'
      );
    }
  ),

  # The Continuity Way
  C(
    ContinuousLogin => [ '/continuous_login' ],
    get => sub {
      my ($self) = @_;
      my $cr = $self->cr;
    },
    queue => { get => 'continuous_login' },
  ),

);

package OpenID::Consumer::Views;

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
          title('OpenID Consumer')
        ),
        body(
          h1('OpenID Consumer'),
          x($content)
        ),
      )->as_HTML;
    },
    home => sub {
      my ($self, $v) = @_;
      form({action=>R('Login'), method=>'post'},
        h2(
          x("OpenID: "),
          input({type=>'text', name=>'openid'}),
          input({type=>'submit', name=>'action', value=>'Login'}),
        )
      )->as_HTML;
    },
  )
);

1;
