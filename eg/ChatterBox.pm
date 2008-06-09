package ChatterBox;
use base 'Squatting';
use Data::Dump 'pp';

our %state;
sub service {
  my ($app, $c, @args) = @_;
  my $cr = $c->cr;

  # setup session and vars
  my $sid = $cr->{session_id};
  if (defined $sid) {
    $c->state = $state{$sid} ||= {};
  } 
  if ($c->state->{u}) {
    $c->v->{u} = $c->state->{u};
  }

  $app->SUPER::service($c, @args);
}

package Object;
use strict;
use selfvars;

our $AUTOLOAD;

sub new {
  bless { %opts } => $_[0];
}

sub clone {
  bless { %$self, %opts } => ref($self);
}

sub AUTOLOAD {
  my $attr = $AUTOLOAD;
  $attr =~ s/.*://;
  if (ref($self->{$attr}) eq 'CODE') {
    $self->{$attr}->($self, @args)
  } else {
    if (@args) {
      $self->{$attr} = $args[0];
    } else {
      $self->{$attr};
    }
  }
}

sub DESTROY {
}

package ChatterBox::Controllers;
use selfvars;
use base 'Squatting::Q';
use Squatting ':controllers';

our @messages;

our @C = (
  C(
    Home => [ '/' ],
    get  => sub {
      my $v = $self->v;
      $self->render('chatter_box');
    },
  ),
  C(
    Id => [ '/id' ],
    post => sub {
      my $input = $self->input;
      if ($input->{name}) {
        my $user = Object->new({name => $input->{name}});
        $self->state->{u} = $user;
      }
      $self->redirect(R('Home'));
    }
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
      my $input = $self->input;
      $self->redirect(R('Home'));
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
    layout => sub {
      my ($v, @content) = @args;
      html(
        head(
          title('ChatterBox'),
          style(x("body { background: #456; color: #fff; }")),
          style(x($self->{_css})),
        ),
        body( @content )
      )->as_HTML;
    },
    _css => qq|
      div#chatter_box {
        padding: 8px;
        min-height: 240px;
        max-width: 320px;
        background: #122;
        color: #cfc;
        font-family: "Trebuchet MS", sans-serif;
        font-size: 9pt;
        border: 1px solid #466;
        -moz-border-radius: 7px;
      }
      div#chatter_box dl {
        margin: 0;
        padding: 4px;
        height: 200px;
        background: #000;
        color: #fe8;
        border: 1px solid #888;
        overflow-x: hidden;
        overflow-y: auto;
      }
      div#chatter_box dt {
        font-weight: bold;
      }
      div#chatter_box dd {
        margin-top: -1.25em;
        margin-left: 5em;
      }
      div#chatter_box div.input {
        margin-top: 0.5em;
      }
      div#chatter_box div.input input {
        font-family: "Trebuchet MS", sans-serif;
        font-size: 9pt;
      }
      div#chatter_box div.input input.text {
        width: 260px;
      }
    |,
    _widget => sub {
      my ($v) = @args;
      form({ id=> 'chatter_box_form', method => 'post', action => R('Event') },
        div({ id => 'chatter_box' },
          dl(
            map {
              dt('beppu'),
              dd("what's up? "),
              dt('pip'),
              dd('the sky. ' x 10),
            } (1..20)
          ),
          ($v->{u} 
            ? 
            (
              div({ class => 'input' },
                input({ type => 'text',   name => 'message', class => 'text' }),
                input({ type => 'submit', name => 'submit',  value => 'Say' }),
              ),
            ) 
            : ()
          )
        ),
      )
    },
    _id => sub {
      my ($v) = @args;
      unless ($v->{u}) {
        form({ method => 'post', action => R('Id') },
          h1("What's your name?"),
          input({ type => 'text', name => 'name' }),
          input({ type => 'submit', name => 'submit', value => 'Submit' }),
        );
      } else {
        ()
      }
    },
    chatter_box => sub {
      $self->_id(@args),
      $self->_widget(@args);
    },
  )
);

1;
