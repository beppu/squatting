package Squatting::With::Log;

#use strict;
#no  strict 'refs';
#use warnings;

sub service {
  my ($app, $c, @args) = @_;
  my $config = \%{$app.'::CONFIG'};
  $c->log ||= Squatting::Log->new($config);
  $app->next::method($c, @args);
}

package Squatting::Log;

#use strict;
#no  strict 'refs';
#use warnings;
use IO::All;

our $log;

sub new {
  my ($class, $config) = @_;
  return $log if ($log);
  my $path   = $config->{'with.log.path'}   || '='; # (default STDERR)
  my $level  = $config->{'with.log.levels'} || 'debug,info,warn,error,fatal';
  my $levels = +{ map { $_ => 1 } split(/\s*,\s*/, $level) };
  $log = bless({ path => $path, levels => $levels } => $class);
}

sub timestamp {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  sprintf(
    '%d-%02d-%02dT%02d:%02d:%02d',
    $year + 1900, $mon + 1, $mday,
    $hour, $min, $sec
  );
}

for my $level (qw(debug info warn error fatal)) {
  *{$level} = sub {
    my ($self, @messages) = @_;
    my $is_level = "is_$level";
    return unless $self->$is_level;
    for (@messages) {
      sprintf('%-5s %s ! %s'."\n", $level, timestamp, $_) >> io($self->{path});
    }
  };
  *{"is_$level"} = sub {
    $_[0]->{levels}->{$level};
  };
}

sub enable {
  my $self = shift;
  $self->{levels}->{$_} = 1 for (@_);
}

*{"levels"} = \&enable;

sub disable {
  my $self = shift;
  $self->{levels}->{$_} = 0 for (@_);
}

1;

=head1 NAME

Squatting::With::Log - a simple error log for Squatting apps

=head1 SYNOPSIS

Adding simple logging to your Squatting app:

  use App 'With::Log', 'On::CGI';

This will let log from within your controllers:

  C(
    Day => [ '/(\d+)/(\d+)/(\d+)' ],
    get => sub {
      my ($self, $year, $month, $day) = @_;
      my $log = $self->log;
      $log->debug(" year: $year");
      $log->info ("month: $month");
      $log->warn ("  day: $day");
      # you also get $log->error and $log->fatal
      $self->render('day');
    }
  )

=head1 DESCRIPTION

Squatting::With::Log provides a simple logging object that can be used from
within your controllers to send messages to either a log file or STDERR for
informational purposes.  Typically, these messages would be useful during
development and debugging but would be disabled during production.

=cut
