package Guess;
use Squatting;

package Guess::Controllers;

our @C = (
       C(
               Home => [ '/' ],
               get => sub {
                       my ($self) = @_;
                       $self->redirect(R('Guess'));
               },
       ),

       C(
               Guess => [ '/guess' ],
               get => sub {
                       my ($self) = @_;

                       my $cr = $self->cr;

                       my $rand100 = sub { int(rand(100)) };
                       my $to_guess = $rand100->();
                       my $tries = 0;

                       while(1) {
                               my $n = $cr->param('n');
                               $cr->print(qq|
                                       <html>
                                               <head>
                                               </head>
                                               <body>
                               |);
                               $cr->print(qq|
                                       Guess a number from 0 to 100<br/>
                                       |. sub {
                                               if ($n) {
                                                       return "<i>The guess is invalid.</i>" if $n !~ /\d+/;
                                                       return ($n<$to_guess)
                                                               ?       "<i>The answer is higher.</i>"
                                                               : ($n>$to_guess)
                                                                       ?       "<i>The answer is lower.</i>"
                                                                       :       "<i>You guessed it in $tries tries</i>";
                                               }
                                       }->() . qq|
                                       <form method="get" />
                                       |. (($n!=$to_guess)
                                               ? (qq|
                                                               <input type="text" name="n" />
                                                               <input type="submit" value="guess" />
                                                       |)
                                               : sub {
                                                       $tries = 0;
                                                       $to_guess = $rand100->();
                                                       return "<a href=\"/guess\">start again</a>"
                                               }->()
                                       ) .     qq|

                                       </form>
                               |);
                               $cr->print(qq|
                                               </body>
                                       </html>
                               |);
                               $cr->next;

                               $tries++;
                       } # while
               },
               continuity => 1,
       ),

);

1;
