use ExtUtils::MakeMaker;

WriteMakefile (
  NAME          => 'Squatting',
  AUTHOR        => 'John BEPPU <beppu@cpan.org>',
  LICENSE       => 'mit',
  VERSION_FROM  => 'lib/Squatting.pm',
  ABSTRACT_FROM => 'lib/Squatting.pm',
  EXE_FILES     => [ 'bin/squatting', 'bin/vw' ],
  PREREQ_PM     => {
    'Class::C3::Componentised' => 0,
    'HTTP::Daemon'             => 0,
    'Continuity'               => 0.991,
    'Data::Dump'               => 0,
    'JSON::XS'                 => 0,
    'Shell::Perl'              => 0,
  },
  depend => { distmeta => 'metamunge' }
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

sub MY::postamble {q{
metamunge :
	$(NOECHO) $(ECHO) 'no_index:'        >> $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '    directory:'   >> $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '        - eg'     >> $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) '        - t'      >> $(DISTVNAME)/META.yml

nd :
	$(MKPATH) doc
	$(MKPATH) /tmp/squatting-doc
	nd -r -i lib -o HTML doc -p /tmp/sqautting-doc
}}
