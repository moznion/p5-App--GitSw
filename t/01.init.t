#!perl

use strict;
use warnings;
use utf8;
use File::Copy;
use File::Spec::Functions qw/catfile/;
use File::Path;
use FindBin;

use App::GitSw;

use Test::More tests => 4;
use Test::File;

my $test_dir             = catfile( $FindBin::Bin, 'resource', 'init_test' );
my $git_dir              = catfile( $test_dir,     'git_dir' );
my $gitsw_dir            = catfile( $test_dir,     '.gitsw' );
my $default_profile_path = catfile( $gitsw_dir,    'default' );
my $moved_config_file = catfile( $default_profile_path, 'config' );

# Preprocessing
rmtree($gitsw_dir) if ( -d $gitsw_dir );
my $config = catfile( $git_dir, 'config' );
unlink $config if ( -l $config );
File::Copy::copy( catfile( $git_dir, 'config.orig' ), $config );

my $app = App::GitSw->new($git_dir);
$app->run('init');

subtest 'Make .gitsw dir' => sub {
    dir_exists_ok($gitsw_dir);
    dir_exists_ok($default_profile_path);
};

subtest 'Move the config file to "default" from git directory' => sub {
    file_exists_ok($moved_config_file);
};

subtest 'Symlink refers certainly target' => sub {
    my $symlink_config_file = catfile( $git_dir, 'config' );
    symlink_target_is( $symlink_config_file, $moved_config_file );
};

subtest 'Profile file content is certainly' => sub {
    open my $fh, '<', catfile($gitsw_dir, '.gitsw_profile') or die "$!";
    my $current = do { local $/; <$fh> };
    close $fh;
    chomp $current;
    is $current, 'default';
};

done_testing;
