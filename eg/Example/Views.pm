package Example::Views;

use strict;
use warnings;
                        # Long before Markaby or HAML, there was CGI.pm.
use CGI ':standard';    # CGI.pm => DSLs since before they were cool.  ;-)
use JSON::XS;
use Data::Dump 'dump';
use Squatting ':views';

our %V;
our @V = (

  V(
    'html',
    layout => sub {
      my ($self, $v, @body) = @_;
      join "", start_html('Example'),
        div({-id => 'header'},
          h1('Example'), 
          ul({-id => 'menu'},
            li(a({-href => '/'},            "home")),
            li(a({-href => '/?foo=1&bar=2&baz=5'}, "home + cgi")),
            li(a({-href => '/@count'},      "count"), span('[RESTless]')),
            li(a({-href => '/~beppu'},      "profile")),
            li(a({-href => '/~beppu.json'}, "profile.json")),
            li(a({-href => '/env'},         "env")),
            li(a({-href => '/env.json'},    "env.json")),
            li(a({-href => '/rubygems'},    "redirect to rubygems")),
            li(a({-href => '/droids-you-are-looking-for'}, "404")),
          ),
        ),
        div({-id => 'content'}, @body),
      end_html;
    },
    home => sub {
      my ($self, $v) = @_;
      h2("Home"),
      h3('$v -- Template Variables'),
      pre(encode_json($v)),
      h3('\%input -- CGI Variables'),
      pre(encode_json($v->{input})),
      p('This is an example Squatting application.')
    },
    profile => sub {
      my ($self, $v) = @_;
      h2("Profile of $v->{name}"),
      p("$v->{name} is a fascinating person."),
      h2("Special Hack"),
      p({-id => 'secret'}, $v->{_secret_from_json});
    },
    env => sub {
      my ($self, $v) = @_;
      h2("env"),
      pre(dump($v));
    },
  ),

  V(
    'json',
    profile => sub {
      my ($self, $v) = @_;
      delete $v->{_secret_from_json};
      encode_json($v);
    },
    _ => sub {
      my ($self, $v) = @_;
      encode_json($v);
    }
  )

);

1;
