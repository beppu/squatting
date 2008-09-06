package Example;
use base 'Squatting';
use Example::Controllers;
use Example::Views;

use PODServer;
$Pod::Simple::HTML::Perldoc_URL_Prefix = '/pod/';
Example->mount('PODServer', '/pod');

1;
