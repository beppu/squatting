package UniCodePoints;

warn 'export PERL_UNICODE=SD  # before running this app' 
  unless $ENV{PERL_UNICODE} =~ /S/ && $ENV{PERL_UNICODE} =~ /D/;

use base 'Squatting';
use strict;
use warnings;

# squatting UniCodePoints --show-config
# squatting UniCodePoints --config count=256 -c bg='#112' -c fg='#ccc'
our %CONFIG = (
  count => 1024,
  bg    => '#ffffff',
  fg    => '#000000',
  a     => '#44a',
  ah    => '#ccf',
);

package UniCodePoints::Controllers;
use Squatting ':controllers';
our @C = (
  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      my $input = $self->input;
      my $v     = $self->v;
      my $start = $input->{start};
      $start ||= 0;
      my $count = $input->{count} || $CONFIG{count};
      $v->{chars} = [ map { chr($_) } ($start .. ($start + $count - 1)) ];
      $v->{prev} = { count => $count, start => (($start - $count) < 0) ? 0 : $start - $count };
      $v->{next} = { count => $count, start => $start + $count };
      $self->render('home');
    }
  )
);

package UniCodePoints::Views;
use Squatting ':views';
use HTML::AsSubs;

sub x {
  map { HTML::Element->new('~literal', text => $_) } @_;
}

my $C = \%UniCodePoints::CONFIG;
our @V = (
  V(
    'html',

    layout => sub {
      my ($self, $v, @content) = @_;
      html(
        head(
          title("unicode codepoints"),
          style($self->_css),
        ),
        body(
          x(@content),
        ),
      )->as_HTML;
    },

    _css => sub {qq|
      body {
        font-size: 10pt;
        background: $C->{bg};
        color: $C->{fg};
      }
      a {
        color: $C->{a};
        text-decoration: none;
      }
      a:hover {
        color: $C->{ah};
      }
      td {
        padding: 8px;
        width: 88px;
        font-family: monospace;
      }
      tr td:last-child {
        font-family: sans-serif;
      }
    |},

    home => sub {
      my ($self, $v) = @_;
      div(
        x($self->_pager($v)),
        table(
          map { 
            my $o = ord($_);
            &tr(
              td(sprintf('0x%04X', $o)),
              td(sprintf('&#x%04X;', $o)),
              td($_),
            ) 
          } @{$v->{chars}}
        ),
        x($self->_pager($v)),
      )->as_HTML;
    },

    _pager => sub {
      my ($self, $v) = @_;
      div(
        a({ href => R('Home', $v->{prev}) }, "<prev"),
        x(" | "),
        a({ href => R('Home', $v->{next}) }, "next>"),
      )->as_HTML;
    },

  ),
);
