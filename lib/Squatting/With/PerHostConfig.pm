package Squatting::With::PerHostConfig;
use common::sense;

#
# It's up to you to define a custom class method called lookup_config_for_host!
#

# Given a host, return a config hashref.
sub config_for_host {
  my ($class, $host) = @_;
  if ($class->can('lookup_config_for_host')) {
    return $class->lookup_config_for_host($host);
  } else {
    return undef;
  }
}

# If a custom config is found, merge %CONFIG with the contents of the custom config.
sub service {
  no strict 'refs';
  my ($class, $c, @args) = @_;
  my $host_config = $class->config_for_host($c->env->{HTTP_HOST});
  if ($host_config) {
    my $config = \%{$class . "::CONFIG"};
    local %{$class . "::CONFIG"} = %$config;
    for (keys %$host_config) {
      ${$class . "::CONFIG"}{$_} = $host_config->{$_};
    }
    $class->next::method($c, @args);
  } else {
    $class->next::method($c, @args);
  }
}

1;

__END__

=head1 NAME

Squatting::With::PerHostConfig - vary %CONFIG based on $c->env->{HTTP_HOST}

=head1 SYNOPSIS

First, define a lookup_config_for_host method.

  use Rhetoric 'With::PerHostConfig';
  {
    package Rhetoric;
    our %HOST_CONFIG = (
      'localhost' => {
        theme => 'default',
      },
      'test1.local' => {
        theme => 'scary',
      },
      m.local => {
        theme => 'mobile',
      },
    );

    # How you choose to implement this method is completely up to you.
    # Feel free to pull data from a database if you so desire.

    sub lookup_config_for_host {
      my ($class, $host) = @_;
      return $HOST_CONFIG{$host};
    }
  }

=head1 DESCRIPTION

This plugin lets you vary a Squatting app's %CONFIG based on the host name
used to make the HTTP request.

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
=cut
