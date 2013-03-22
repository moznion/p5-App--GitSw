#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::GitSw' );
}

diag( "Testing App::GitSw $App::GitSw::VERSION" );

done_testing;
