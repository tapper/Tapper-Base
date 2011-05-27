#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tapper::Action' );
}

diag( "Testing Tapper::Action $Tapper::Action::VERSION, Perl $], $^X" );
