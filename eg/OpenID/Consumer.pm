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
use Data::Dump 'pp';

sub csr {
  my ($self) = @_;
  return Net::OpenID::Consumer->new(
    ua    => LWPx::ParanoidAgent->new,
    cache => Cache::File->new(cache_root => '/tmp/openid-consumer-cache'),
    args  => $self->input,
    consumer_secret => '...',
    required_root   => 'http://work:4234/'
  );
}

our @C = (

  C(
    Home => ['/'],
    get => sub {
      my ($self) = @_;
      $self->render('home');
    },
  ),

  C(
    Login => [ '/login' ],
    get => sub {
      my ($self) = @_;
      my $csr = csr($self);
      $self->headers->{'Content-Type'} = 'text/plain';
      if (my $setup_url = $csr->user_setup_url) {
        # redirect/link/popup user to $setup_url
        $self->redirect($setup_url);
        return;
      } elsif ($csr->user_cancel) {
        # restore web app state to prior to check_url
        return "user_cancel";
      } elsif (my $vident = $csr->verified_identity) {
         my $verified_url = $vident->url;
         return "verified_url $verified_url !";
      } else {
         return "Error validating identity: " . $csr->err;
      }
    },
    post => sub {
      my ($self) = @_;
      my $input = $self->input;
      my $csr = csr($self);
      my $claimed_identity = $csr->claimed_identity($input->{openid});
      my $check_url = $claimed_identity->check_url(
        return_to  => "http://work:4234/login",
        trust_root => "http://work:4234/",
      );
      $self->redirect($check_url);
    },
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
