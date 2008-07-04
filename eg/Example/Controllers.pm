package Example::Controllers;

use strict;
use warnings;

use Squatting ':controllers';
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
      $self->render('home')
    }
  ),

  C(
    Profile => [ '/~(\w+)\.?(\w+)?' ],
    get     => sub {
      my ($self, $name, $format) = @_;
      $format ||= 'html';
      my $v            = $self->v;
      $v->{name}       = $name;
      $v->{controller} = $self->name;
      $v->{_secret_from_json} = 
        'The JSON view will purposely omit this data, '.
        'because the $V{json}->profile template was written to '.
        'ignore the key, _secret_from_json.';
      $self->render('profile', $format)
      # This will use the _specific_ json template called 'profile'
      #   if ($format eq 'json').
    }
  ),

  C(
    Count => [ '/@count' ],
    # GET requests to the Count controller have the following properties:
    # - They are sent to a different session queue.
    # - The session queue is named "${session_id}.count".
    # - The queue => { get => 'count' } is what made this happen.
    # - Squatting::Mapper treats controllers with a queue attribute specially.
    # - It will run GET requests in their own coroutine separate from the 
    #   RESTful controllers.
    # - This coroutine may handle many more HTTP requests.
    get => sub {
      my ($self) = @_;
      my $cr     = $self->cr;
      my $i      = 1;
      while (1) {
        # - In fact, this one won't ever return control back to Squatting.
        # - You're in Continuity land, now.
        $cr->print($i++);
        $cr->next;
      }
    },
    post => sub {
    },
    queue => { get => 'count' }
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
