package MicroWiki; use base 'Squatting'; package MicroWiki::Controllers;
use Squatting ':controllers'; use IO::All; @C = C( Page => ['/', '/(\w+)', 
'/(\w+).(edit)' ], get => sub { $_[1] ||= 'Home'; -f $_[1] || 'Edit' > 
io($_[1]); $x < io($_[1]); $_[0]->v->{page} = $_[1]; $_[0]->v->{text} = $x; 
$_[0]->render($_[2] && 'edit' || 'page') }, post => sub { $_[0]->input->{text}
> io($_[1]); $_[0]->redirect(R('Page', $_[1])) }); package MicroWiki::Views; 
use Squatting ':views'; use Text::Textile 'textile'; our @V = (V(html, page => 
sub { '<a href="'.R('Page',$_[1]->{page},'edit').'">edit</a>'.textile($_[1]->
{text})},edit=>sub{sprintf('<form method="post" action="%s"><textarea name='.
'"text" rows="24" cols="80">%s</textarea><div><input type="submit"/></div>'.
'</form>',R('Page', $_[1]->{page}) ,$_[1]->{text})})); 1
