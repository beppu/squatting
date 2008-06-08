package Example;
use base 'Squatting';
use Example::Controllers;
use Example::Views;
use PODServer;
Example->mount('PODServer', '/pod');
1;
