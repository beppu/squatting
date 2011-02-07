package CouchWiki;
use strict;
use warnings;
use Squatting;
use Coro::AnyEvent;

our %CONFIG = (
  db => 'couchwiki'
);

#_____________________________________________________________________________
package CouchWiki::Models;
use strict;
use warnings;
use AnyEvent::CouchDB;
use Text::Textile;
use Clone 'clone';

# $db = db
our $DB;
our $DESIGN_PAGES = {
  _id      => "_design/pages",
  language => "javascript",
  views    => { 
    recent => { 
      map  => "function(doc) { if (doc.type == 'Page') emit(doc.created_date, doc); }", 
    }, 
  },
};
sub db {
  $DB || do {
    $DB = couchdb($CouchWiki::CONFIG{db});
    eval { $DB->info->recv; };
    if ($@) {
      $DB->create->recv;
      $DB->save_doc($DESIGN_PAGES)->recv;
    }
    $DB;
  };
}

# timestamp - I had no idea this would be 60x faster than:  DateTime->now."";
sub timestamp {
  my ($sec,$min,$hour,$mday,$mon,$year) = gmtime;
  sprintf(
    '%d-%02d-%02dT%02d:%02d:%02d',
    $year+1900,$mon+1,$mday,
    $hour,$min,$sec
  );
}

# $doc = page('WikiPageTitle');
# $doc = page('WikiPageTitle' => 'new text for page');
our $PAGE    = { type => 'Page', raw => 'Edit me.', html => '<div>Edit me.</div>' };
our $TEXTILE = Text::Textile->new(disable_html => 1);
sub page {
  my ($title, $text) = @_;
  my $db = db;
  my $doc;
  eval { $doc = $db->open_doc($title)->recv; };
  if (!$doc) {
    $doc = clone($PAGE);
    $doc->{_id} = $title;
  }
  if ($text) {
    $doc->{raw} = $text;
    $doc->{html} = $TEXTILE->process($text);
    $doc->{created_date} = timestamp;
    $db->save_doc($doc)->recv;
  }
  return $doc;
}

# $pages = recent_changes();
sub recent_changes {
  my $db = db;
  my $results = $db->view('pages/recent', { descending => "true" })->recv;
  my @pages = map { $_->{value} } @{$results->{rows}};
  return \@pages;
}

#_____________________________________________________________________________
package CouchWiki::Controllers;
use strict;
use warnings;
use AnyEvent::CouchDB;

*page = \&CouchWiki::Models::page;
*recent_changes = \&CouchWiki::Models::recent_changes;

our @C = (

  C(
    Page => [ '/', '/(\w+)', '/(\w+).(edit)' ],
    get  => sub {
      my ($self, $title, $edit) = @_;
      $title ||= 'Home';
      $self->v->{page} = page($title);
      $self->v->{title} = $title;
      if ($edit) {
        $self->render('edit');
      } else {
        $self->render('page');
      }
    },
    post => sub {
      my ($self, $title) = @_;
      page($title => $self->input->{text});
      $self->redirect( R('Page', $title) );
    }
  ),

  C(
    RecentChanges => [ '/@recent_changes' ],
    get => sub {
      my ($self) = @_;
      $self->v->{title} = "Recent Changes";
      $self->v->{pages} = recent_changes();
      $self->v->{no_edit} = 1;
      $self->render('recent_changes');
    }
  ),

);

#_____________________________________________________________________________
package CouchWiki::Views;
use strict;
use warnings;
use HTML::AsSubs;

sub span  { HTML::AsSubs::_elem('span', @_) }
sub thead { HTML::AsSubs::_elem('thead', @_) }
sub tbody { HTML::AsSubs::_elem('tbody', @_) }
sub x     { map { HTML::Element->new('~literal', text => $_) } @_ }

our @V = (
  V('html',

    layout => sub {
      my ($self, $v, $content) = @_;
      html(
        head(
          title($v->{title})
        ),
        body(
          div({ id => 'couchwiki' },
            x($self->_menu($v)),
            x($content),
          )
        ),
      )->as_HTML;
    },

    _menu => sub {
      my ($self, $v) = @_;
      div(
        a({ href => R('RecentChanges') }, 'Recent Changes'),
        span(' | '),
        a({ href => R('Page', 'Home') },  'Home'),
        do {
          unless ($v->{no_edit}) {
            (
              span(' | '),
              a({ href => R('Page', $v->{title}, 'edit') }, 'Edit This Page'),
            );
          } else {
            ()
          }
        },
      )->as_HTML;
    },

    page => sub {
      my ($self, $v) = @_;
      div(
        div(x($v->{page}->{html}))
      )->as_HTML;  
    },

    edit => sub {
      my ($self, $v) = @_;
      div(
        form(
          {
            method => 'post',
            action => R('Page', $v->{page}->{_id}),
          },
          textarea(
            {
              name => 'text',
              cols => '80',
              rows => '24',
            },
            $v->{page}->{raw}
          ),
          div(input({ type => 'submit' })),
        ),
      )->as_HTML;
    },

    recent_changes => sub {
      my ($self, $v) = @_;
      div(
        ul(
          map { 
            li(
              a({ href => R('Page', $_->{_id}) }, $_->{_id})
            ) 
          } @{$v->{pages}}
        )
      )->as_HTML;
    },

  )
);

1;
