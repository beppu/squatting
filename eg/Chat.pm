package Chat;
use base 'Squatting';

# This is a port of eg/chat-ajax-push.pl from the Continuity distribution.
# We're using the exact same JavaScript, but we've switched the server side
# with a Squatting implementation.  Let's see if they can taste the difference.

package Chat::Controllers;
use selfvars;
use Squatting ':controllers';

our @messages;
our $got_message;

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      $self->render('home');
    },
  ),

  C(
    PushStream => [ '/pushstream/' ],
    get   => sub {
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
    queue => { get => 'pushstream' },
  ),

  C(
    SendMessage => [ '/sendmessage/' ],
    post => sub {
      my $input = $self->input;
      my $msg   = $input->{message};
      my $name  = $input->{username};
      if ($msg) {
        unshift @messages, "$name: $msg";
        pop @messages if $#messages > 15;
      }
      $got_message = 1;
      "Got it!";
    },
  ),

);

package Chat::Views;
use selfvars;
use Squatting ':views';
use HTML::AsSubs;

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
              input({ type => 'submit', id => 'sendbutton', name => 'sendbutton', value => 'Send', }),
              b({ id => 'status' }, "?")
            ),
            div({ id => 'log' }, '-- no messages yet --')
          )
        )
      )->as_HTML;
    }
  )
);

1;
