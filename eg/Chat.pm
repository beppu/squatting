package Chat;
use base 'Squatting';

package Chat::Controllers;
use selfvars;
use base 'Squatting::Q';
use Squatting ':controllers';

our @messages;
our $got_message;

our @C = (
  C(
    Home => [ '/' ],
    get  => sub {
      $self->render('chat');
    },
  ),
  C(
    PushStream => [ '/pushstream/' ],
    get   => sub : Q(pushstream) {
      my $cr = $self->cr;
      my $w  = Coro::Event->var(var => \$got_message, poll => 'w');
      while (1) {
        print STDERR "**** GOT MESSAGE, SENDING ****\n";
        my $log = join("<br>", @messages);
        $cr->print($log);
        $cr->next;
        print STDERR "**** Waiting for got_message indicator ****\n";
        $w->next;
      }
    },
  ),
  C(
    SendMessage => [ '/sendmessage/' ],
    post => sub {
      my $cr = $self->cr;
      my $msg = $cr->param('message');
      my $name = $cr->param('username');
      if($msg) {
        unshift @messages, "$name: $msg";
        pop @messages if $#messages > 15;
      }
      $got_message = 1;
      "Got it!";
    },
  )
);

package Chat::Views;
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
    home => sub {
      my ($v) = @args;
      html(
        head(
          title('Chat'),
          script({ src => 'jquery.js' }),
          script({ src => 'chat-ajax-push.js' }),
        ),
        body(
          form({ id=> 'f', method => 'get', action => R('SendMessage') },
            div(
              input({ type => 'text', id => 'username', name => 'username', size => 10 }),
              input({ type => 'text', id => 'message',  name => 'message',  size => 50 }),
              input({
                type  => 'submit',
                id    => 'sendbutton',
                name  => 'sendbutton',
                value => 'Send',
              }),
            ),
            div({ id => 'log' }, '-- no messages yet --')
          )
        )
      )->as_HTML;
    }
  )
);

1;
