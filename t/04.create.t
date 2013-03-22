#!perl

use strict;
use warnings;
use utf8;
use Config::Simple;
use File::Path;
use File::Spec::Functions qw/catfile/;
use FindBin;

use App::GitSw;

use Test::More tests => 4;
use Test::File;
use Test::Exception;
use Test::MockObject::Extends;

my $test_dir  = catfile( $FindBin::Bin, 'resource', 'create_test' );
my $git_dir   = catfile( $test_dir,     '.git' );
my $gitsw_dir = catfile( $test_dir,     '.gitsw' );
my $luke      = catfile( $gitsw_dir,    'luke' );

rmtree($luke) if ( -d $luke );

my $app      = App::GitSw->new($git_dir);
my $app_mock = Test::MockObject::Extends->new($app);
$app_mock->mock(
    '_ask_user_data',
    sub {
        return 'MIKE', 'mike@example.com';
    }
);

$app_mock->run( 'create', 'luke' );

subtest 'Create the individual profile directory' => sub {
    dir_exists_ok($luke);
};

subtest 'Verify the contents of profile file' => sub {
    my $config = Config::Simple->new( catfile( $luke, 'config' ) );

    my $core_config = $config->param( -block => 'core' );
    my $expected = {
        'repositoryformatversion' => 0,
        'filemode'                => 'true',
        'bare'                    => 'false',
        'logallrefupdates'        => 'true'
    };
    is_deeply $core_config, $expected;

    my $user_config = $config->param( -block => 'user' );
    $expected = {
        'name'  => 'MIKE',
        'email' => 'mike@example.com',
    };
    is_deeply $user_config, $expected;
};

subtest 'Should fail because argument is not enough' => sub {
    throws_ok { $app->run('create') }
    qr/Usage: \$ gitsw create \[profile name\]/;
    dies_ok { $app->run('create') };
};

subtest 'Should fail because creating profile name already exists' => sub {
    throws_ok { $app->run( 'create', 'default' ) }
    qr/'default' already exists\./;
    dies_ok { $app->run( 'create', 'default' ) };
};

done_testing;
