package PODServer;
use base 'Squatting';

package PODServer::Controllers;
use Squatting ':controllers';
use File::Basename;
use File::Find;
use Config;

# figure out where all(?) our pod is located
# (loosely based on zsh's _perl_basepods and _perl_modules)
our %perl_basepods = map {
  my ($file, $path, $suffix) = fileparse($_, ".pod");
  ($file => $_);
} glob "$Config{installprivlib}/pod/*.pod";

our %perl_modules;
our @perl_modules;
sub scan {
  for (@INC) {
    my $inc = $_;
    my $wanted = sub {
      my $m = $File::Find::name;
      next if -d $m;
      next unless /\.(pm|pod)$/;
      $m =~ s/$inc//;
      $m =~ s/\.\w*$//;
      $m =~ s{^/}{};
      $perl_modules{$m} = $File::Find::name;
    };
    find($wanted, $_);
  }
  my %h = map { $_ => 1 } ( keys %perl_modules, keys %perl_basepods );
  @perl_modules = sort keys %h;
}
scan;

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      $self->v->{title} = 'POD Server';
      $self->render('home');
    }
  ),

  # The job of this controller is to take $module
  # and find the file that contains the POD for it.
  # Then it asks the view to turn the POD into HTML.
  C(
    Pod => [ '/pod/(.*)' ],
    get => sub {
      my ($self, $module) = @_;
      my $v        = $self->v;
      $v->{path}   = [ split('/', $module) ];
      $v->{module} = $module;
      if (exists $perl_modules{$module}) {
        $v->{pod_file} = $perl_modules{$module};
        $v->{title} = "POD Server - $module";
        $self->render('pod');
      } elsif (exists $perl_basepods{$module}) {
        $v->{pod_file} = $perl_basepods{$module};
        $v->{title} = "POD Server - $module";
        $self->render('pod');
      } else {
        $v->{title} = "POD Server - $v->{module}";
        $self->render('pod_not_found');
      }
    }
  )
);

package PODServer::Views;
use Squatting ':views';
use Data::Dump 'pp';
use HTML::AsSubs;
use Pod::Simple;
use Pod::Simple::HTML;
$Pod::Simple::HTML::Perldoc_URL_Prefix = '/pod/';

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
          style(x($self->_css))
        ),
        body(
          div({ id => 'menu' }, a({ href => R('Home')}, "Home"), ($self->_breadcrumbs($v)) ),
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
        div#pod {
          width: 540px;
          margin: 2em 4em 2em 4em;
        }
        div#pod pre {
          padding: 0.5em;
          background: #000;
          border: 1px solid #444;
          color: #ccd;
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

    _js => sub {
      $JS ||= join('', <DATA>);
    },

    home => sub {
      $HOME ||= ul(
        map {
          my $pm = $_;
          $pm =~ s{/}{::}g;
          li(
            a({ href => R(Pod, $_) }, $pm )
          )
        } (sort @perl_modules)
      );
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
            a({ href => R(Pod, $_) }, $colon->($_))
          )
        } @possibilities
      );
    }

  )
);

1;
