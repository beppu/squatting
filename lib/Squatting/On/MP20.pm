package Squatting::On::MP20;

sub mp20 {
}

1;

=head1 NAME

Squatting::On::MP20 - mod_perl 2.0 support for Squatting

=head1 SYNOPSIS

Load

  <Perl>
    use App 'On::MP20';
    App->init
  </Perl>

Setup handler

  <Location />
    SetHandler perl-script
    PerlHandler App
  </Location>

VirtualHost Configuration Example

  ...

=head1 DESCRIPTION

=head1 API

=head2 Something Clever

=head3 App->mp20

=head1 SEE ALSO

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
