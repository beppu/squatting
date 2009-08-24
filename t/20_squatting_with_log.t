use strict;
use warnings;
use Test::More;
use Squatting::With::Log;

my $Log = $Squatting::With::Log::Log;

our @tests = (

  sub {
    can_ok($Log, qw(_path enable disable levels debug info warn error fatal is_debug is_info is_warn is_error is_fatal));
  },

  sub {
    my $log = $Log->clone();
    ok($log->_path eq '=', "The log should output to STDERR by default.");
  },

  sub {
    my $log = $Log->clone();
    ok((not $log->is_debug), "The debug level should be OFF by default.");
  },

  sub {
    my $log = $Log->clone();
    $log->enable('debug');
    ok($log->is_debug, "The enable method should turn a level on.");
  },

);

plan tests => scalar(@tests);

for my $test (@tests) { $test->() }
