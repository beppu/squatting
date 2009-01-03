package Squatting::Controller;
sub new{bless{name=>$_[1],urls=>$_[2],@_[3..$#_]}=>$_[0]}
sub clone{bless{%{$_[0]},@_[1..$#_]}=>ref($_[0])}
for my$m qw(name urls cr env input cookies state v status headers log view app){
*{$m}=sub:lvalue{$_[0]->{$m}}}
for my$m qw(get post head put delete options trace connect){
*{$m}=sub{$_[0]->{$m}->(@_)}}sub param{my($self,$k,@v)=@_;
if(defined $k){if(@v){$self->input->{$k}=((@v>1)?\@v:$v[0]);
}else{$self->input->{$k}}
}else{keys%{$self->input}}}
sub render{my($self,$template,$vn)=@_;my$view;$vn||=$self->view;
my$app=$self->app;if(defined($vn)){$view=${$app."::Views::V"}{$vn}; 
}else{$view=${$app."::Views::V"}[0]}
$view->headers=$self->headers;$view->$template($self->v)}
sub redirect{my($self,$l,$s)=@_;$self->headers->{Location}=$l||'/';
$self->status=$s||302}my$not_found=sub{$_[0]->status=404;
$_[0]->env->{REQUEST_PATH}." not found."};
our$r404=Squatting::Controller->new(R404=>[],
get=>$not_found,post=>$not_found,app=>'Squatting');
package Squatting;
use base"Class::C3::Componentised";use List::Util"first";use URI::Escape;
use Carp;our$VERSION='0.60';sub import{my$m=shift;my$p=(caller)[0];my$app=$p;
$app=~s/::Controllers$//;$app=~s/::Views$//;if(UNIVERSAL::isa($app,'Squatting')
){*{$p."::R"}=sub{my($controller,@args)=@_;my$input;if(@args && ref($args[-1])
eq'HASH'){$input=pop(@args)}my$c=${$app."::Controllers::C"}{$controller};
croak"$controller controller not found"unless$c;my$arity=@args;
my$path=first{my@m=/\(.*?\)/g;$arity==@m}@{$c->urls};
croak"couldn't find a matching URL path" unless $path;
while($path=~/\(.*?\)/){
$path=~s{\(.*?\)}{uri_escape(+shift(@args),"^A-Za-z0-9\-_.!~*’()/")}e}
if($input){$path.="?".join('&'=>map{my$k=$_;ref($input->{$_})eq'ARRAY'
?map{"$k=".uri_escape($_)}@{$input->{$_}}:"$_=".uri_escape($input->{$_})
}keys %$input)}$path};
*{$app."::D"}=sub{my$url=uri_unescape($_[0]);
my$C=\@{$app.'::Controllers::C'};my($c,@regex_captures);for$c(@$C){
for(@{$c->urls}){if(@regex_captures=($url=~qr{^$_$})){
pop @regex_captures if($#+==0);return($c,\@regex_captures)}}}
($Squatting::Controller::r404,[])}unless exists ${$app."::"}{D}}
my@c;for(@_){if($_ eq':controllers'){*{$p."::C"}=sub{
Squatting::Controller->new(@_,app=>$app)};
}elsif($_ eq':views'){*{$p."::V"}=sub{Squatting::View->new(@_)};
}elsif(/::/){push @c,$_}}$m->load_components(@c)if@c}
sub component_base_class{__PACKAGE__}sub mount{my($app,$other,$prefix)=@_;
push @{$app."::O"},$other;push @{$app."::Controllers::C"},map{
my$urls=$_->urls;$_->urls=[map{$prefix.$_}@$urls];$_;
}@{$other."::Controllers::C"}}
sub relocate{my($app,$prefix)=@_;for(@{$app."::Controllers::C"}){
my$urls=$_->urls;$_->urls=[map{$prefix.$_}@$urls]}}
sub init{$_->init for(@{$_[0]."::O"});%{$_[0]."::Controllers::C"}=
map{$_->name=>$_}@{$_[0]."::Controllers::C"};
%{$_[0]."::Views::V"}=map{$_->name=>$_}@{$_[0]."::Views::V"}}
sub service{my($app,$c,@args)=grep{defined}@_;my$method=lc
$c->env->{REQUEST_METHOD};my$content;eval{$content=$c->$method(@args)};
warn"EXCEPTION: $@"if($@);my$cookies=$c->cookies;$c->headers->{'Set-Cookie'}=
join("; ",map{CGI::Cookie->new(-name=>$_,%{$cookies->{$_}})}
grep{ref$cookies->{$_}eq'HASH'}keys %$cookies)if(%$cookies);$content}
package Squatting::View;sub new{
my$class=shift;my$name=shift;bless{name=>$name,@_}=>$class}
sub name:lvalue{$_[0]->{name}};sub headers:lvalue{$_[0]->{headers}}
sub _render{my($self,$template,$vars,$alt)=@_;$self->{template}=$template;
if(exists$self->{layout}&&($template!~/^_/)){$template=$alt if defined$alt;
$self->{layout}($self,$vars,$self->{$template}($self,$vars));
}else{$template=$alt if defined $alt;$self->{$template}($self,$vars)}}
sub AUTOLOAD{my($self,$vars)=@_;my$template=$AUTOLOAD;
$template=~s/.*://;if(exists$self->{$template}&&ref($self->{$template})eq
'CODE'){$self->_render($template,$vars)}elsif(exists$self->{_}){
$self->_render($template,$vars,'_')}else{die(
"$template cannot be rendered.")}};sub DESTROY{};1;
