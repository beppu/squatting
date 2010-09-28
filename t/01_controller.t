use Test::More;
use strict;
use warnings;

{
  package Foo;
  use Squatting;

  package Foo::Controllers;
  our @C = (
    C(
      'Home' => ['/'],
      get => sub {
        "home";
      }
    )
  );
}

sub c {
  $Foo::Controllers::C[0]
}

our @tests = (

  sub {
    my $c = c;
    isa_ok($c, 'Squatting::Controller');
    return $c;
  },

  sub {
    my $c = c;
    can_ok($c, qw(name urls cr env input cookies state v status headers view app));
  },

  sub {
    my $c = c;
    $c->{headers} = { };
    $c->redirect('/foo');
    ok($c->headers->{Location} eq '/foo' && $c->status == 302, '$c->redirect should set the Location header to /foo and the status to 302.')
  },

  sub {
    my $c = c;
    ok($c->get eq "home", '$c->get should return the content for a GET request.');
  }

);

plan tests => scalar(@tests);

for my $test (@tests) { $test->() }
