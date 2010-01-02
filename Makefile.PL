use ExtUtils::MakeMaker;

WriteMakefile1(
  META_MERGE => {
    resources => {
      repository => 'http://github.com/beppu/squatting',
    },
  },
  #BUILD_REQUIRES => {
  #},

  NAME          => 'Squatting',
  AUTHOR        => 'John BEPPU <beppu@cpan.org>',
  LICENSE       => 'mit',
  VERSION_FROM  => 'lib/Squatting.pm',
  ABSTRACT_FROM => 'lib/Squatting.pm',
  EXE_FILES     => [ 'bin/squatting' ],
  PREREQ_PM     => {
    'Class::C3::Componentised' => 0,
    'HTTP::Daemon'             => 0,
    'Continuity'               => 0.991,
    'Data::Dump'               => 0,
    'JSON::XS'                 => 0,
    'Shell::Perl'              => 0,
    'IO::All'                  => 0,
    'Test::More'               => 0,
    'HTTP::Response'           => 0,
    'Clone'                    => 0,
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

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}

