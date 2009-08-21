#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Artemis::Base' );
}

diag( "Testing Artemis::Base $Artemis::Base::VERSION, Perl $], $^X" );
