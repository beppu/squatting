package UTF8;
use base 'Squatting';

# == How to Run This App ==
#
#   squatting UTF8
#   squatting UTF8 -c view=raw
#   squatting UTF8 -c view=as_subs
#   squatting UTF8 -c view=crash
#

our %CONFIG = (
  view => 'raw'  # or 'as_subs' or 'crash'
);

sub service {
  my ($app, $c, @args) = @_;
  $c->view = $CONFIG{view};
  $app->next::method($c, @args);
}

package UTF8::Controllers;
use strict;
use warnings;
use Squatting ':controllers';

our @C = (
  C(
    Home => [ '/' ],
    get => sub {
      my ($self) = @_;
      $self->render('home');
    }
  ),
);


package UTF8::Views;
use strict;
use warnings;
use Squatting ':views';
use Encode;
use HTML::AsSubs;

sub utf8 {
  join('', map { encode('utf8', $_) } @_);
}

sub x { map { HTML::Element->new('~literal', text => $_) } @_ }

our @V = (
  V(
    'raw',
    layout => sub {
      my ($self, $v, $content) = @_;
      qq|
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            <title>UTF-8 Hacking</title>
            <style>
              body {
                background: #211;
                color:      #f33;
              }
              h1 {
                font-size: 52pt;
              }
            </style>
          </head>
          <body>$content</body>
        </html>
      |;
    },
    home => sub {
      utf8("<h1>\x{5225}\x{5e9c} \x{8061}</h1>");
    },
  ),

  V(
    'as_subs',
    layout => sub {
      my ($self, $v, $content) = @_;
      html(
        head(
          title('UTF-8 Hacking'),
        ),
        body(
          x($content)
        )
      )->as_HTML;
    },
    home => sub {
      my ($self, $v) = @_;
      h1("\x{5225}\x{5e9c} \x{8061}")->as_HTML;
    },
  ),

  V(
    'crash',
    home => sub {
      "\x{5225}\x{5e9c} \x{8061}"
    }
  ),

);

1;
