package Wiki;

#
# XXX - This app is still under construction!  It probably doesn't work, yet.
#

use base 'Squatting';
our %CONFIG = (
  home_page       => 'HomePage',
  js_base_url     => '/',         # set to false to disable javascript
  anonymous_edits => 1,
  page_directory  => '/tmp/wiki',
);

#_____________________________________________________________________________
package Wiki::Page;
use strict;
use warnings;

sub new {
  my ($class, $name) = @_;
  bless({ name => $name }, $class);
}

sub body {
}

sub save {
}

#_____________________________________________________________________________
package Wiki::Page::RecentChanges;
use strict;
use warnings;
use base 'Wiki::Page';

sub new {
  my ($class) = @_;
  bless({ name => 'RecentChanges' }, $class);
}

sub add {
  my ($self, $change_message, $by) = @_;
  $self;
}

#_____________________________________________________________________________
package Wiki::Controllers;
use strict;
use warnings;
use Squatting ':controllers';

sub disallow_anonymous_posters {
  my ($v) = @_;
  ((not $Wiki::CONFIG{anonymous_edits}) && (not exists($v->{u})))
}

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      my $page = Wiki::Page->new($Wiki::CONFIG{home_page});
      # $self->render('page');
      return "work in progress";
    }
  ),

  C(
    RecentChanges => [ '/RecentChanges' ],
    get => sub {
    }
  ),

  C(
    Page => [ '/(\w+)' ],
    get  => sub {
      my ($self, $name) = @_;
      my $v = $self->v;
      $v->{page} = Wiki::Page->new($name);
    },
    post => sub {
      my ($self, $name) = @_;
      my $v      = $self->v;
      my $input  = $self->input;
      if (disallow_anonymous_posters($v)) {
        $self->redirect(R('Page', $name));
        return;
      }
      $v->{page} = Wiki::Page->new($name);
      $v->{page}->body($input->{body});
      $v->{page}->save;
      my $recent_changes = Wiki::Page::RecentChanges->new;
      $recent_changes->add($input->{message}, $v->{u});
      $self->redirect($input->{redirect_to});
    }
  ),

  C(
    PageEdit => [ ],
  ),

);

#_____________________________________________________________________________
package Wiki::Views;
use strict;
use warnings;
use Squatting ':views';
use HTML::AsSubs;

sub x {
  map { HTML::Element->new('~literal', text => $_) } @_;
}

our @V = (
  V(
    html,
    layout => sub {
      my ($self, $v, $content) = @_;
      html(
        head(
          title('Wiki')
        ),
        body(
          div({ id => 'wiki' }, $content)
        )
      )->as_HTML;
    },
    page => sub {
      my ($self, $v) = @_;
    },
    _page => sub {
      my ($self, $v) = @_;
    },
    page_edit => sub {
      my ($self, $v) = @_;
    }
  )
);

1;
