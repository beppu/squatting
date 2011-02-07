package PODServer;
use Squatting;

package PODServer::Controllers;
use File::Basename;
use File::Find;
use Config;

# skip files we've already seen
my %already_seen;

# figure out where all(?) our pod is located
# (loosely based on zsh's _perl_basepods and _perl_modules)
our %perl_basepods = map {
  my ($file, $path, $suffix) = fileparse($_, ".pod");
  $already_seen{$_} = 1;
  ($file => $_);
} glob "$Config{installprivlib}/pod/*.pod";

our %perl_modules;
our @perl_modules;
sub scan {
  for (@INC) {
    next if $_ eq ".";
    my $inc = $_;
    my $pm_or_pod = sub {
      my $m = $File::Find::name;
      next if -d $m;
      next unless /\.(pm|pod)$/;
      next if $already_seen{$m};
      $already_seen{$m} = 1;
      $m =~ s/$inc//;
      $m =~ s/\.\w*$//;
      $m =~ s{^/}{};
      $perl_modules{$m} = $File::Find::name;
    };
    find({ wanted => $pm_or_pod, follow_fast => 1 }, $_);
  }
  my %h = map { $_ => 1 } ( keys %perl_modules, keys %perl_basepods );
  @perl_modules = sort keys %h;
}
scan;
%already_seen = ();

# *.pod takes precedence over *.pm
sub pod_for {
  for ($_[0]) {
    return $_ if /\.pod$/;
    my $pod = $_;
    $pod =~ s/\.pm$/\.pod/;
    if (-e $pod) {
      return $pod;
    }
    return $_;
  }
}

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      $self->v->{title} = 'POD Server';
      if ($self->input->{base}) {
        $self->v->{base} = 'pod';
      }
      $self->render('home');
    }
  ),

  C(
    Frames => [ '/@frames' ],
    get    => sub {
      my ($self) = @_;
      $self->v->{title} = 'POD Server';
      $self->render('_frames');
    }
  ),

  # The job of this controller is to take $module
  # and find the file that contains the POD for it.
  # Then it asks the view to turn the POD into HTML.
  C(
    Pod => [ '/(.*)' ],
    get => sub {
      my ($self, $module) = @_;
      my $v        = $self->v;
      my $pm       = $module; $pm =~ s{/}{::}g;
      $v->{path}   = [ split('/', $module) ];
      $v->{module} = $module;
      if (exists $perl_modules{$module}) {
        $v->{pod_file} = pod_for $perl_modules{$module};
        $v->{title} = "POD Server - $pm";
        $self->render('pod');
      } elsif (exists $perl_basepods{$module}) {
        $v->{pod_file} = pod_for $perl_basepods{$module};
        $v->{title} = "POD Server - $pm";
        $self->render('pod');
      } else {
        $v->{title} = "POD Server - $v->{module}";
        $self->render('pod_not_found');
      }
    }
  )
);

package PODServer::Views;
use Data::Dump 'pp';
use HTML::AsSubs;
use Pod::Simple;
use Pod::Simple::HTML;
$Pod::Simple::HTML::Perldoc_URL_Prefix = '/';

# the ~literal pseudo-element -- don't entity escape this content
sub x {
  HTML::Element->new('~literal', text => $_[0])
}

our $JS;
our $HOME;

our @V = (
  V(
    'html',

    layout => sub {
      my ($self, $v, @content) = @_;
      html(
        head(
          title($v->{title}),
          style(x($self->_css)),
          (
            $v->{base} 
              ? base({ target => $v->{base} })
              : ()
          ),
        ),
        body(
          div({ id => 'menu' },
            a({ href => R('Home')}, "Home"), ($self->_breadcrumbs($v))
          ),
          div({ id => 'pod' }, @content),
        ),
      )->as_HTML;
    },

    _breadcrumbs => sub {
      my ($self, $v) = @_;
      my @breadcrumb;
      my @path;
      for (@{$v->{path}}) {
        push @path, $_;
        push @breadcrumb, a({ href => R('Pod', join('/', @path)) }, " > $_ ");
      }
      @breadcrumb;
    },

    _css => sub {
      qq|
        body {
          background: #112;
          color: wheat;
          font-family: 'Trebuchet MS', sans-serif;
          font-size: 10pt;
        }
        h1, h2, h3, h4 {
          margin-left: -1em;
        }
        pre {
          font-size: 9pt;
          background: #000;
          color: #ccd;
        }
        code {
          font-size: 9pt;
          font-weight: bold;
          color: #fff;
        }
        a {
          color: #fc4;
          text-decoration: none;
        }
        a:hover {
          color: #fe8;
        }
        div#menu {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          background: #000;
          color: #fff;
          opacity: 0.75;
        }
        ul#list {
          margin-left: -6em;
          list-style: none;
        }
        div#pod {
          width: 580px;
          margin: 2em 4em 2em 4em;
        }
        div#pod pre {
          padding: 0.5em;
          border: 1px solid #444;
          -moz-border-radius-bottomleft: 7px;
          -moz-border-radius-bottomright: 7px;
          -moz-border-radius-topleft: 7px;
          -moz-border-radius-topright: 7px;
        }
        div#pod h1 {
          font-size: 24pt;
          border-bottom: 2px solid #fe2;
        }
        div#pod p {
          line-height: 1.4em;
        }
      |;
    },

    home => sub {
      $HOME ||= div(
        a({ href => R(Home),   target => '_top' }, "no frames"),
        em(" | "),
        a({ href => R(Frames), target => '_top' }, "frames"),
        ul({ id => 'list' },
          map {
            my $pm = $_;
            $pm =~ s{/}{::}g;
            li(
              a({ href => R('Pod', $_) }, $pm )
            )
          } (sort @perl_modules)
        )
      );
    },

    _frames => sub {
      my ($self, $v) = @_;
      html(
        head(
          title($v->{title})
        ),
        frameset({ cols => '*,340' },
          frame({ name => 'pod',  src => R('Pod', 'Squatting') }),
          frame({ name => 'list', src => R('Home', { base => 'pod' }) }),
        ),
      )->as_HTML;
    },

    pod => sub {
      my ($self, $v) = @_;
      my $out;
      my $pod = Pod::Simple::HTML->new;
      $pod->index(1);
      $pod->output_string($out);
      $pod->parse_file($v->{pod_file});
      $out =~ s{%3A%3A}{/}g;
      $out =~ s/^.*<!-- start doc -->//s;
      $out =~ s/<!-- end doc -->.*$//s;
      x($out), $self->_possibilities($v);
    },

    pod_not_found => sub {
      my ($self, $v) = @_;
      div(
        p("POD for $v->{module} not found."),
        $self->_possibilities($v)
      )
    },

    _possibilities => sub {
      my ($self, $v) = @_;
      my @possibilities = grep { /^$v->{module}/ } @perl_modules;
      my $colon = sub { my $x = shift; $x =~ s{/}{::}g; $x };
      hr,
      ul(
        map {
          li(
            a({ href => R('Pod', $_) }, $colon->($_))
          )
        } @possibilities
      );
    }

  )
);

1;
