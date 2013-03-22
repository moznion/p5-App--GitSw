use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name              => 'App-GitSw',
    module_name       => 'App::GitSw',
    script_files      => ['gitsw'],
    license           => 'perl',
    dist_author       => 'moznion <moznion@gmail.com>',
    dist_version_from => 'lib/App/GitSw.pm',
    build_requires    => {
        'Test::More'                => '0.98',
        'Test::MockObject::Extends' => '1.20120301',
        'Test::Exception'           => '0.31',
        'Test::File'                => '1.34',
        'Config::Simple'            => '4.58',
        'FindBin'                   => 0,
        'File::Copy'                => 0,
        'File::Path'                => 0,
        'File::Spec::Functions'     => 0,
    },
    configure_requires => { 'Module::Build' => '0.40' },
    requires           => {
        perl             => '5.008004',
        'File::Basename' => 0,
        'Carp'           => 0,
        'Cwd'            => 0,
    },
    no_index   => { 'directory' => ['inc'] },
    meta_merge => {
        'resources' => {
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'git://github.com/moznion/p5-App--GitSw.git',
        },
    },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
    add_to_cleanup       => ['App-GitSw-*'],
    create_license       => 1,
    create_readme        => 1,
);

$builder->create_build_script();
