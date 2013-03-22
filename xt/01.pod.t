#!perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw/catfile/;

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

my @targets = ('lib', catfile($FindBin::Bin, '..', 'README.pod'));
all_pod_files_ok(@targets);
