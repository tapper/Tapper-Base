#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Tapper::Base' );
}

diag( "Testing Tapper::Action $Tapper::Action::VERSION, Perl $], $^X" );
