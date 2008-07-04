package UniCodePoints;
use base 'Squatting';
use strict;
use warnings;
our %CONFIG = (
  count => 256
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
  HTML::Element->new('~literal', text => $_[0])
}

our @V = (
  V(
    'html',

    layout => sub {
      my ($self, $v, @content) = @_;
      html(
        head(
          title("unicode codepoints"),
        ),
        body(
          x(@content),
        ),
      )->as_HTML;
    },

    home => sub {
      my ($self, $v) = @_;
      div(
        x($self->_pager($v)),
        table(
          map { 
            &tr(
              td(sprintf('%x', ord($_))),
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
