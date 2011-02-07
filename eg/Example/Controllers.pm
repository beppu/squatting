package Example::Controllers;

use strict;
use warnings;

use Data::Dump qw(dump);

sub add { my $sum = 0; $sum += $_ for(@_); $sum }

our @C = (

  C(
    Home => [ '/' ],
    get  => sub {
      my ($self)  = @_;
      my $v       = $self->v;
      my $input   = $self->input;
      $v->{life}  = 'good';
      $v->{bavl}  = 'realized';
      $v->{input} = $input;
      if (%$input) {
        $v->{sum} = add(values %$input);
      }
      $self->log->debug('home sweet home');
      $self->render('home')
    }
  ),

  C(
    Profile => [ '/~(\w+)\.?(\w+)?' ],
    get     => sub {
      my ($self, $name, $format) = @_;
      $format ||= 'html';
      $self->log->info("format is $format");
      my $v             = $self->v;
      $v->{name}        = $name;
      $v->{controller}  = $self->name;
      $v->{description} = "$name is hoping for the best.";
      $v->{_secret_from_json} =
        'The JSON view will purposely omit this data, '.
        'because the $V{json}->profile template was written to '.
        'ignore the key, _secret_from_json.';
      $self->render('profile', $format)
      # This will use the _specific_ json template called 'profile'
      #   if ($format eq 'json').
    }
  ),

  # This controller shows you how $self->cookies handles
  # both incoming AND outgoing cookies.
  # - incoming cookies are stored in the $self->cookies hashref as strings
  # - outgoing cookies are stored in the $self->cookies hashref as hashrefs
  #     that can be fed to CGI::Cookie
  C(
    Cookie => [ '/cookies' ],
    get => sub {
      my ($self) = @_;
      $self->v->{cookies} = [
        map {
          {
            name  => $_,
            value => $self->cookies->{$_},
          }
        } sort keys %{$self->cookies}
      ];
      $self->render('cookies');
    },
    post => sub {
      my ($self) = @_;
      my $input  = $self->input;
      my $name   = $input->{name};
      my $value  = $input->{value};
      $self->cookies->{$name} = { -value => $value };
      $self->redirect(R('Cookie'));
    },
  ),

  C(
    Count => [ '/@count' ],
    # Requests to the Count controller run in a separate coroutine.
    # - The (continuity => 1) tells Squatting::Mapper to take notice
    #   of this controller and put requests to this controller in
    #   a different "session queue".  In Continuity-speak, being in
    #   a different "session queue" means you get your own coroutine.
    continuity => 1,

    get => sub {
      my ($self) = @_;
      my $cr     = $self->cr;
      my $i      = 1;
      # Infinite loops are allowed in Continuity controllers.
      while (1) {
        # - Typically, you won't ever return control back to Squatting.
        # - You're in Continuity land, now.
        $cr->print($i++);
        # $cr->next blocks until the next request comes in.
        $cr->next;
      }
    },
  ),

  C(
    RubyGems => [ '/rubygems' ],
    get      => sub {
      my ($self) = @_;
      $self->redirect('http://localhost:8808/');
    }
  ),

  C(
    Env => [ '/env', '/env.json' ],
    get => sub {
      my ($self) = @_;
      my $v = $self->v = $self->env;
      my $format = ($v->{REQUEST_PATH} eq '/env')
        ? 'html'
        : 'json';
      $self->render('env', $format);
      # This will use the generic json template called '_'
      #   if ($format eq 'json').
      # The generic template, '_', is used
      #   when no other template can be found.
    }
  ),

);


1;
