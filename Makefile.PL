use ExtUtils::MakeMaker;

WriteMakefile (
    'NAME'          => 'Squatting',
    'AUTHOR'        => 'John Beppu <beppu@cpan.org>',
    'VERSION_FROM'  => 'lib/Squatting.pm',
    'ABSTRACT_FROM' => 'lib/Squatting.pm',
    'EXE_FILES'     => [ 'bin/squatting' ],
    'PREREQ_PM'     => {
	'HTTP::Daemon'     => 0,
        'Continuity'       => 0.991,
        'Data::Dump'       => 0,
        'JSON::XS'         => 0,
        'Shell::Perl'      => 0,
    },
);

sub MY::libscan {
    my $self = shift;
    $_       = shift;

    # $self appears to be a blessed hashref that contains
    # all the attributes/value pairs passed to WriteMakeFile()
    # plus some other MakeMaker-related info.

    return 0 if /\.sw.$/ || /~$/;
    return $_;
}
