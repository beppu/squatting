package Squatting::With::Themes;

use strict;
use warnings;

our %THEMES;

# find and load every module named App::Themes::*
sub init {
  my ($app) = @_;
  my @themes;
  for (@INC) {
    my $theme_dir = "$_/$app/Theme";
    if (-d $theme_dir) {
      push @themes, glob("$theme_dir/*.pm");
    }
  }
  for (@themes) {
    $app->add_theme($_);
  }
  $THEMES{$app} = \@themes;
}

sub service {
  my ($app, $c, @args) = @_;
  $c->view = $c->state->{'squatting.with.themes'};
  $app->next::method($c, @args);
}

sub themes {
  my ($app) = @_;
  $THEMES{$app}
}

sub add_theme {
  my ($app, $theme, $force) = @_;
  my $va = \@{$app."::Views::V"};
  my $vh = \%{$app."::Views::V"};
  if ($force || not exists $$vh{$theme->name}) {
    push @$va, $theme;
    $$vh{$theme->name} = $theme;
  } else {
    warn "A view called '".$theme->name."' already exists in $app.";
    undef;
  }
}

sub remove_theme {
  my ($app, $theme_name) = @_;
  my $va = \@{$app."::Views::V"};
  my $vh = \%{$app."::Views::V"};
  my $i = 0;
  my $found;
  while ($va->[$i]) {
    if ($va->[$i]->name eq $theme_name) {
      $found = $i;
      last;
    }
    $i++
  }
  if ($found) {
    delete $$vh{$theme_name};
    splice(@{ $THEMES{$app} }, $found, 1);
    splice(@$va,               $found, 1);
  }
}

1;

__END__

=head1 NAME

Squatting::With::Themes - themable Squatting apps

=head1 SYNOPSIS

  use App 'On::PSGI', 'With::Themes';

Make a controller to change themes
  
  C(
    Theme => [ '/theme' ]
    get => sub {
    },
    post => sub {
    },
  ),

=head1 DESCRIPTION

One of Squatting's 

=head1 API

=head3 init

=head3 service

=head3 themes

=head3 add_theme

=head3 remove_theme

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=cut
