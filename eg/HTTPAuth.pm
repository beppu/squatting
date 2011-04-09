package HTTPAuth;
use Squatting;

our %CONFIG = (
  login    => 'bob',
  password => 'freeman',
);

sub service {
  my ($app, $c, @args) = @_;
  $c->headers->{'Content-Type'} = 'text/html; charset=utf-8';
  $app->next::method($c, @args);
}

package HTTPAuth::Controllers;
use strict;
use warnings;
use MIME::Base64;

sub authorized {
  my $self = shift;
  return undef unless defined $self->env->{HTTP_AUTHORIZATION};
  my $auth = $self->env->{HTTP_AUTHORIZATION};
  $auth =~ s/Basic\s*//;
  my $login_pass =  encode_base64("$CONFIG{login}:$CONFIG{password}", '');
  if ($auth eq $login_pass) {
    return 1;
  } else {
    return 0;
  }
}

our @C = (
  C(
    Home => [ '/' ],
    get => sub {
      my ($self) = @_;
      $self->render('home');
    }
  ),
  C(
    Secret => [ '/secret' ],
    get => sub {
      my ($self) = @_;
      if (authorized($self)) {
        $self->render('secret');
      } else {
        $self->status = 401;
        $self->headers->{'WWW-Authenticate'} = 'Basic realm="Secret"';
        $self->render('unauthorized');
      }
    }
  ),
  C(
    Himitsu => [ '/himitsu' ],
    get => sub {
      my ($self) = @_;
      if (authorized($self)) {
        $self->render('himitsu');
      } else {
        $self->status = 401;
        $self->headers->{'WWW-Authenticate'} = 'Basic realm="Secret"';
        $self->render('unauthorized');
      }
    }
  )
);

package HTTPAuth::Views;
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
      html(
        head(
          title('HTTP Auth Demo')
        ),
        body(
          x($content)
        )
      )->as_HTML;
    },
    home => sub {
      my ($self, $v) = @_;
      div(
        h1("Which one would you like?"),
        ul(
          li(a({ href => R('Secret')  }, 'Secret'    )),
          li(a({ href => R('Himitsu') }, x('ひみつ') )),
        ),
      )->as_HTML;
    },
    secret => sub {
      my ($self, $v) = @_;
      div(
        a({ href => R('Home') }, 'Return'),
        p("George W. Bush is the grandson of Aleister Crowley."),
      )->as_HTML;
    },
    himitsu => sub {
      my ($self, $v) = @_;
      div(
        a({ href => R('Home') }, x('戻る')),
        p(x("自由になるため、仕事をやめた。"))
      )->as_HTML;
    },
    unauthorized => sub {
      div(
        h1('Psst!'),
        small(qq[The login is "$CONFIG{login}" and the password is "$CONFIG{password}".]),
      )->as_HTML;
    },
  )
);

1;
