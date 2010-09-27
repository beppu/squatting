use MicroWiki 'On::PSGI';
MicroWiki->init;

my $app = sub {
  my $env = shift;
  MicroWiki->psgi($env);
};
