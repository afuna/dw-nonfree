package LJ::S2Theme::sundaymorning;
use base qw( LJ::S2Theme );

sub layouts { ( "2l" => "two-columns-left" ) }
sub layout_prop { "layout_type" }

sub designer { "Calla" }


package LJ::S2Theme::sundaymorning::greensquiggle;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw() }

package LJ::S2Theme::sundaymorning::greenswirls;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw() }

package LJ::S2Theme::sundaymorning::pinkswirls;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw() }

package LJ::S2Theme::sundaymorning::purpleswirls;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw() }

package LJ::S2Theme::sundaymorning::redsquiggle;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw( featured ) }

package LJ::S2Theme::sundaymorning::yellowsquiggle;
use base qw( LJ::S2Theme::sundaymorning );
sub cats { qw() }

1;

