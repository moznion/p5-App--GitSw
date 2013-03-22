#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::GitSw;

use Test::More tests => 1;

my $test_dir  = catfile( $FindBin::Bin, 'resource', 'list_test' );
my $git_dir   = catfile( $test_dir,     '.git' );
my $gitsw_dir = catfile( $test_dir,     '.gitsw' );

subtest 'Get certainly profiles list' => sub {
    my $app = App::GitSw->new($git_dir);
    my $got = $app->run('list');

    my $profiles = @$got[0];
    my $current = @$got[1];

    my $expected = [ 'default', 'smith', 'tom' ];
    @$expected = sort @$expected;
    is_deeply $profiles, $expected;
    is $current, 'tom';
};

done_testing;
