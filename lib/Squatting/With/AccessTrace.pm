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
  my $referer = (defined $c->env->{HTTP_REFERER}) ? "# ".$c->env->{HTTP_REFERER} : " ";
  warn sprintf('%5d ', $I++),
    "[$s] $app->$meth(@{[ join(', '=>map { \"'$_'\" } $c->name, @args) ]}$ppi) $referer\n";
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
request.  It looks like this:

    1 [200] Example->get('Home')
    2 [200] Example->get('Home', { bar => 2, baz => 5, foo => 1 })
    3 [200] Example->get('Profile', 'beppu')
    4 [200] Example->get('Home')
    5 [302] Example->get('RubyGems')
    6 [404] Squatting->get('R404')

You also get the number of requests the current process has served and the
HTTP status of the response in the first and second columns, respectively.

The code that generates this was originally in C<&Squatting::service>, but I
wanted to make it optional, so I moved it into a separate module.

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
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
