#!perl

use strict;
use warnings;
use utf8;

use FindBin;
use File::Copy;
use File::Spec::Functions qw/catfile/;
use File::Path;

use App::GitSw;

use Test::More tests => 4;
use Test::Exception;
use Test::File;

my $test_dir      = catfile( $FindBin::Bin, 'resource', 'switch_test' );
my $git_dir       = catfile( $test_dir,     '.git' );
my $gitsw_dir     = catfile( $test_dir,     '.gitsw' );
my $gitsw_profile = catfile( $gitsw_dir,    '.gitsw_profile' );

rmtree($git_dir) if ( -d $git_dir );
mkpath($git_dir);
unlink $gitsw_profile if ( -f $gitsw_profile );
File::Copy::copy( catfile( $gitsw_dir, '.gitsw_profile.orig' ),
    $gitsw_profile );

my $app = App::GitSw->new($git_dir);
$app->run( 'switch', 'smith' );

subtest 'Rewrite profile file successfully' => sub {
    open my $fh, '<', catfile( $gitsw_dir, '.gitsw_profile' ) or die "$!";
    my $current = do { local $/; <$fh> };
    close $fh;
    chomp $current;
    is $current, 'smith';
};

subtest 'Change the refer target of symlink successfully' => sub {
    my $config_from = catfile( $git_dir, 'config' );
    my $config_to = catfile( $gitsw_dir, 'smith', 'config' );
    symlink_target_is( $config_from, $config_to );
};

subtest 'Should fail because argument is not enough' => sub {
    throws_ok { $app->run('switch') }
    qr/Usage: \$ gitsw switch \[profile name\]/;
    dies_ok { $app->run('switch') };
};

subtest 'Should fail because specified profile does not exist' => sub {
    throws_ok { $app->run( 'switch', 'NON-EXIST' ) }
    qr/'NON-EXIST' does not exist\./;
    dies_ok { $app->run( 'switch', 'NON-EXIST' ) };
};

done_testing;
