package Squatting::With::Mount;
use strict;
use warnings;

sub mount {
  my ($class, $path, $app, @plugins) = @_;
  # load the app
  # make the app use the 'On::Squatting' plugin
  # load other plugins if @plugins
  # create a controller object
  # plug the app into this controller
  # push the controller into @C
}

1;

__END__

=head1 NAME

Squatting::With::Mount - mount Squatting apps at arbitrary paths

=head1 SYNOPSIS

  use App 'With::Mount';
  App->mount('/forum' => 'Ground');
  App->init;

=head1 DESCRIPTION

This adds a C<mount> method to your Squatting application that lets
you mount other Squatting applications at arbitrary paths within your
application.

L<Squatting> used to provide a C<mount()> method by default, but I
discovered after the fact that the implementation was flawed.  To do
it correctly would require that I write a lot more code, so I decided
to move the mount method out of the core and into a plugin called
L<Squatting::With::Mount>.

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
