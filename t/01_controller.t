use Test::More;
use Squatting ':controllers';

sub simple_c {
  C(
    'Home' => ['/'],
    get => sub {
      "home";
    }
  );
}

our @tests = (
  sub {
    my $c = C(
      'Home' => ['/'],
      get => sub {
        "home";
      }
    );
    isa_ok($c, 'Squatting::Controller');
    return $c;
  },
  sub {
    my $c = simple_c;
    can_ok($c, qw(name urls cr env input cookies state v status headers view app));
  },
  sub {
    my $c = simple_c;
    $c->{headers} = { };
    $c->redirect('/foo');
    ok($c->headers->{Location} eq '/foo' && $c->status == 302, 
      '$c->redirect should set the Location header to /foo and the status to 302.')
  },
);

plan tests => scalar(@tests);

for (@tests) {
  $_->()
}
