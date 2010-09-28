use Test::More;
use strict;
use warnings;

{
  package Foo;
  use Squatting;

  package Foo::Views;
  use Data::Dump 'pp';
  our @V = (
    V(
      'html',
      layout => sub {
        my ($self, $v, @content) = @_;
        "( @content )";
      },
      home => sub {
        my ($self, $v) = @_;
        "$v->{title}";
      },
      _menu => sub {
        my ($self, $v) = @_;
        "1 2 3 4 5";
      },
      _ => sub {
        my ($self, $v) = @_;
        "$self->{template}";
      }
    )
  );
}

sub v {
  $Foo::Views::V[0]
}

our @tests = (

  sub {
    my $v = v;
    isa_ok($v, 'Squatting::View');
    return $v;
  },

  sub {
    my $v = v;
    can_ok($v, qw(name headers _render));
  },

  sub {
    my $v = v;
    my $body = $v->home({ title => 'home' });
    ok($body eq "( home )", '$v->home({ title => "home" }) should be wrapped by the layout.');
  },

  sub {
    my $v = v;
    my $body = $v->_menu({});
    ok($body eq "1 2 3 4 5", '$v->_menu({}) should NOT be wrapped by the layout.');
  },

  sub {
    my $v = v;
    my $body = $v->missing({});
    ok($body eq "( missing )", '$v->missing({}) should 1) invoke the _ template, 2) set $self->{template}, and 3) be wrapped by layout.');
  },

  sub {
    my $v = v;
    my $body = $v->_missing({});
    ok($body eq "_missing", '$v->_missing({}) should 1) invoke the _ template, 2) set $self->{template}, and 3) NOT be wrapped by layout.');
  },

);

plan tests => scalar(@tests);

for my $test (@tests) { $test->() }
