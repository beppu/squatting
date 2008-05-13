package PODServer;
use base 'Squatting';

package PODServer::Controllers;
use Squatting ':controllers';
use Module::ScanDeps 'add_deps';

our @C = (

  # The job of this controller is to display the home page.
  C(
    Home => [ '/' ],
    get  => sub {
      my ($self) = @_;
      $self->render('home');
    }
  ),

  # The job of this controller is to take $module
  # and find the file that contains the POD for it.
  # Then it has to display the POD as HTML.
  C(
    POD => [ '/pod/(.*)' ],
    get => sub {
      my ($self, $module) = @_;
      my $v   = $self->v;
      my $key = $module;
      $key =~ s{\.html$}{};
      $key =~ s{::}{/}g;
      $key =~ s/$/.pm/;
      my $rv = add_deps($key);
      if ($rv->{$key}) {
        my $pm_file  = $rv->{$key}->{file};
        my $pod_file = $pm_file;
        $pod_file    =~ s/\.pm$/\.pod/;
        my $target;
        if (-e $pod_file) {
          $target = $pod_file;
        } else {
          $target = $rv->{$key}->{file};
        }
        $v->{pod_file} = $target;
        $self->render('pod');
      } else {
        $v->{module} = $module;
        $self->render('pod_not_found');
      }
    }
  )
);

package PODServer::Views;
use Squatting ':views';
use Pod::Simple;
use Pod::Simple::HTML;
$Pod::Simple::HTML::Perldoc_URL_Prefix = '/pod/';

our @V = (
  V(
    'html',
    home => sub {
      my $url = R('POD', 'Squatting');
      qq{<a href="$url">Squatting</a>};
    },
    pod => sub {
      my ($self, $v) = @_;
      my $out;
      my $pod = Pod::Simple::HTML->new;
      $pod->index(1);
      $pod->output_string($out);
      $pod->parse_file($v->{pod_file});
      $out =~ s{%3A%3A}{/}g;
      $out;
    },
    pod_not_found => sub {
      my ($self, $v) = @_;
      qq{POD for $v->{module} not found.};
    }
  )
);

1;
