package Counter;
use Squatting;

package Counter::Controllers;
use strict;
use Tie::IxHash::FixedSize;
use UUID::Random;
use Data::Dump 'pp';

our @C = (
       C(
               Home => [ '/' ],
               get => sub {
                       my ($self) = @_;
                       $self->redirect(R('Count'));
               },
       ),

       C(
               Count => [ '/@count' ],
               get => sub {
                       my ($self) = @_;
                       my $cr     = $self->cr;
                       my $log = $self->log;

                       my %p = (
                               i => 1
                       );
                       my %callbacks;
                       tie my %history, 'Tie::IxHash::FixedSize', {size => 10};

                       my $get_new_ci = sub {
                               my $ci = -1;
                               return sub {
                                       $ci++ if ($ci <= ($cr->param('ci') || $ci));
                                       return $ci;
                               }
                       }->();
                       $history{$get_new_ci->()} = {%p};
                       sub gen_link {
                               my ($text, $code) = @_;
                               my $uuid = UUID::Random::generate;
                                       $callbacks{$uuid} = $code;
                               return qq|<a href="?cb=$uuid&ci=|.($get_new_ci->()).qq|">$text</a>|;
                       }
                       sub process_links {
                               my $cr = shift;
                               my $cb = $cr->param('cb');
                               my $ci = ($cr->param('ci') || 0);
                               $log->debug($ci);
                               if(defined $cb) {
                                       if (exists $callbacks{$cb}
                                               &&      ref($callbacks{$cb}) eq "CODE") {
                                               $callbacks{$cb}->($cr);
                                               delete $callbacks{$cb};
                                               $history{$ci} = {%p};
                                       }       elsif (exists $history{$ci}) {
                                               %p = %{$history{$ci}};
                                       }
                               }
                       }

                       while (1) {
                               process_links($cr);
                               $cr->print(gen_link('next' => sub {
                                               $p{i}++;
                               }));
                               $cr->print("<br />");
                               $cr->print(gen_link('prev' => sub { $p{i}-- }));
                               $cr->print("<br />");
                               $cr->print($p{i});
                               $cr->print("<br />");
                               $cr->next;
                       }
               },
               continuity => 1,
       )
);

1;
