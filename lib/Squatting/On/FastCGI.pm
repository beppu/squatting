package Squatting::On::FastCGI;

use FCGI;

sub fast_cgi {
  my $req = FCGI::Request();
  while($req->Accept() >= 0) {
  }
}

1;
