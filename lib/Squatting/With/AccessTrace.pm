package Squatting::With::AccessTrace;

use Data::Dump 'pp';
our $I = 1;

sub service {
  my ($self, $c, @args) = grep { defined } @_;
  my $body = $self->next::method($c, @args);
  my $meth = lc $c->env->{REQUEST_METHOD};
  my $app  = $c->app;
  my $s    = $c->status;
  my $ppi  = (%{ $c->input })
    ? ', ' . pp($c->input)
    : '';
  warn sprintf('%5d ', $I++),
    "[$s] $app->$meth(@{[ join(', '=>map { \"'$_'\" } $c->name, @args) ]}$ppi)\n";
  $body;
}

1;

=head1 NAME

Squatting::With::AccessTrace - provide a simple access log on STDERR

=head1 SYNOPSIS

  use App 'With::AccessTrace', 'On::Continuity';

=head1 DESCRIPTION

Using this plugin will print an executable line of code that represents the
HTTP request that just came in.  This print out conveniently condenses what
app, HTTP method, controller, arguments, and CGI params were involved in the
request.

This code was originally in C<&Squatting::service>, but I wanted to make it
optional, so I moved it into a separate module.

=cut
