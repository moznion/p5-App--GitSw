#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Path;
use File::Spec::Functions qw/catfile/;

use App::GitSw;

use Test::More tests => 2;
use Test::Exception;

my $test_dir  = catfile( $FindBin::Bin, 'resource', 'nil' );
my $git_dir   = catfile( $test_dir,     '.git' );
my $gitsw_dir = catfile( $test_dir,     '.gitsw' );

subtest 'Should fail because it has not been initialized' => sub {
    rmtree($gitsw_dir) if ( -d $gitsw_dir );
    my $app = App::GitSw->new($git_dir);
    throws_ok { $app->run('list') } qr/Please initialize first!/;
    dies_ok { $app->run('list') };
};

subtest 'Should fail because it fed illegal command' => sub {
    my $default_path = catfile($gitsw_dir, 'default');
    mkpath($default_path);
    open my $fh, '>', catfile($default_path, 'config');
    close $fh;
    open $fh, '>', catfile($gitsw_dir, '.gitsw_profile');
    print $fh 'default';
    close $fh;

    my $app = App::GitSw->new($git_dir);
    dies_ok{$app->run('ILLEGAL_COMMAND')};
};

done_testing;
