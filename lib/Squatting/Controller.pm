package Squatting::Controller;

use strict;
no  strict 'refs';
use warnings;
no  warnings 'redefine';

use CGI::Cookie;

use Squatting ':controllers';

our $AUTOLOAD;

# constructor
sub new {
  bless { name => $_[1], urls => $_[2], @_[3..$#_] } => $_[0];
}

# init w/ Continuity::Request
sub init {
  my ($self, $cr) = @_;
  $self->cr       = $cr;
  $self->env      = e($cr->http_request);
  $self->cookies  = c($self->env->{HTTP_COOKIE});
  $self->input    = i(join('&', grep { defined } ($self->env->{QUERY_STRING}, $cr->request->content)));
  $self->headers  = { 'Content-Type' => 'text/html' };
  $self->v        = {};
  $self->status   = 200;
  $self;
}

# (shallow) copy constructor
sub clone {
  bless { %{$_[0]}, @_[1..$#_] } => ref($_[0]);
}

# name    - name of controller
# urls    - arrayref of URL patterns that this controller responds to
# cr      - Continuity::Request object
# env     - incoming request headers and misc info like %ENV in the CGI days
# input   - incoming CGI variables
# cookies - incoming *AND* outgoing cookies
# state   - your session data
# v       - outgoing vars
# status  - outgoing HTTP Response status
# headers - outgoing HTTP headers
# view    - name of default view
for my $m qw(name urls cr env input cookies state v status headers view) {
  *{$m} = sub : lvalue { $_[0]->{$m} }
}

# HTTP (get post)    ## TODO (put delete head options etc...) ##
for my $m qw(get post) {
  *{$m} = sub { $_[0]->{$m}->(@_) }
}

# $content = $self->render($template, $vars)
sub render {
  my ($self, $template, $vn) = @_;
  my $view;
  $vn ||= $self->view;
  if (defined($vn)) {
    $view = ${$app."::Views::V"}{$vn}; #  hash
  } else {                             #    vs
    $view = ${$app."::Views::V"}[0];   # array -- Perl provides a lot of 'namespaces' so why not use them?
  }
  $view->$template($self->v);
}

# $self->redirect($url, $status_code)
sub redirect {
  my ($self, $l, $s) = @_;
  $self->headers->{Location} = $l || '/';
  $self->status = $s || 302;
}

# \%env = e($http_request)  # Get request headers from HTTP::Request.
sub e {
  my $r = shift;
  my %env;
  my $uri = $r->uri;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = $uri->path;
  $env{REQUEST_URI}    = $uri->path_query;
  $env{REQUEST_METHOD} = $r->method;
  $r->scan(sub{
    my ($header, $value) = @_;
    my $key = uc $header;
    $key =~ s/-/_/g;
    $key = "HTTP_$key";
    $env{$key} = $value;
  });
  \%env;
}

# \%input = i($query_string)  # Extract CGI parameters from QUERY_STRING
sub i {
  my $q = CGI->new($_[0]);
  my %i = $q->Vars;
  +{ map {
    if ($i{$_} =~ /\0/) {
      $_ => [ split("\0", $i{$_}) ];
    } else {
      $_ => $i{$_};
    }
  } keys %i }
}

# \%cookies = c($cookie_header)  # Parse Cookie header(s).
sub c {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
}

# default 404 controller
my $not_found = sub { $_[0]->status = 404; $_[0]->env->{REQUEST_PATH}." not found." };
our $r404 = Squatting::Controller->new(
  R404 => [],
  get  => $not_found,
  post => $not_found
);

1;

=head1 NAME

Squatting::Controller - default controller class for Squatting

=head1 SYNOPSIS

  package App::Controllers;
  use Squatting ':controllers';
  our @C = (
    C(
      Thread => [ '/forum/(\d+)/thread/(\d+)-(\w+)' ],
      get => sub {
        my ($self, $forum_id, $thread_id, $slug) = @_;
        #
        # get thread from database...
        #
        $self->render('thread');
      },
      post => sub {
        my ($self, $forum_id, $thread_id, $slug) = @_;
        # 
        # add post to thread
        #
        $self->redirect(R('Thread', $forum_id, $thread_id, $slug));
      }
    )
  );

=head1 DESCRIPTION

Squatting::Controller is the default controller class for Squatting
applications.  Its job is to take HTTP requests and construct an appropriate
response by setting up output headers and returning content.

=head1 API

=head2 Object Construction

=head3 Squatting::Controller->new($name => \@urls, %methods)

The constructor takes a name, an arrayref or URL patterns, and a hash of
method definitions.  There is a helper function called C() that makes this
slightly less verbose.

=head3 $c->clone([ %opts ])

This will create a shallow copy of the controller.  You may optionally pass in
a hash of options that will be merged into the new clone.

=head3 $c->init($cr)

Given a L<Continuity::Request> object, this method will initialize the controller.

=head2 HTTP Request Handlers

=head3 $c->get(@args)

This method is called when GET requests to the controller are made.

=head3 $c->post(@args)

This method is called when POST requests to the controller are made.

=head2 Attribute Accessors

The following methods are lvalue subroutines that contain information
relevant to the current controller and current request/response cycle.

=head3 $c->name

This returns the name of the controller.

=head3 $c->urls

This returns the arrayref of URL patterns that the controller responds to.

=head3 $c->cr

This returns the L<Continuity::Request> object for the current session.

=head3 $c->env

This returns a hashref populated with a CGI-like environment.  This is where
you'll find the incoming HTTP headers.

=head3 $c->input

This returns a hashref containing the incoming CGI parameters.

=head3 $c->cookies

This returns a hashref that holds both the incoming and outgoing cookies.

Incoming cookies are just simple scalar values, whereas outgoing cookies are
hashrefs that can be passed to L<CGI::Cookie> to construct a cookie string.

=head3 $c->state

If you've setup sessions, this method will return the current session 
data as a hashref.

=head3 $c->v

This returns a hashref that represents the outgoing variables for this
request.  This hashref will be passed to a view's templates when render()
is called.

=head3 $c->status

This returns an integer representing the outgoing HTTP status code.
See L<HTTP::Status> for more details.

=head3 $c->headers

This returns a hashref representing the outgoing HTTP headers.

=head3 $c->view

This returns the name of the default view for the current request.  If
it's undefined, the first view in @App::Views::V will be considered the
default.

=head2 Output

=head3 $c->render($template, [ $view ])

This method will return a string generated by the specified template and view.  If
a view is not specified, the first view object in @App::Views::V will be used.

=head3 $c->redirect($path, [ $status ])

This method is a shortcut for setting $c->status to 302 and $c->headers->{Location}
to the specified URL.  You may optionally pass in a different status code as the
second parameter.

=head1 SEE ALSO

L<Squatting>,
L<Squatting::View>,
L<Squatting::Q>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: f ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: f ***
# End: ***
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
