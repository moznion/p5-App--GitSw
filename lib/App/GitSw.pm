package App::GitSw;

use strict;
use warnings;
use utf8;
use Carp;
use Config::Simple;
use File::Basename qw/dirname/;
use File::Copy;
use File::Path;
use File::Spec::Functions qw/catfile/;

our $VERSION = '0.0.1';

sub new {
    my ( $class, $git_dir ) = @_;
    bless {
        git_dir         => $git_dir,
        git_config_file => catfile( $git_dir, 'config' ),
        gitsw_dir       => catfile( dirname($git_dir), '.gitsw' ),
        gitsw_profile =>
          catfile( dirname($git_dir), '.gitsw', '.gitsw_profile' ),
    }, $class;
}

sub run {
    my ( $self, $command, @args ) = @_;

    if ($command ne 'init') {
        $self->_has_already_initialized();
    }

    my $result = eval { $self->$command(@args) };
    croak "$@" if $@;    # FIXME change error message;

    return $result;
}

sub init {
    my ($self) = @_;
    my $profile = 'default';

    print "Initializing...\n";

    # Create directories as '.gitsw/default/'
    my $default_profile_path = catfile( $self->{gitsw_dir}, $profile );
    mkpath($default_profile_path);

    my $default_profile_config = catfile( $default_profile_path, 'config' );
    File::Copy::move( $self->{git_config_file}, $default_profile_config );

    symlink $default_profile_config, $self->{git_config_file};

    $self->_write_profile($self->{gitsw_profile}, $profile);
}

sub list {
    my ($self) = @_;

    my $profiles = $self->_fetch_profiles_list( $self->{gitsw_dir} );

    open my $fh, '<', $self->{gitsw_profile} or die "$!";
    my $current = do { local $/; <$fh> };
    close $fh;
    chomp($current);

    @$profiles = sort @$profiles;
    foreach my $profile (@$profiles) {
        if ( $profile eq $current ) {
            print '=>';
        }
        else {
            print '  ';
        }
        print "$profile\n";
    }
    print "\n=> : Current Profile\n";

    return [ $profiles, $current ];
}

sub switch {
    my ( $self, $profile ) = @_;

    unless ($profile) {
        $self->_die_if_not_enough_args('switch');
    }

    my $profiles = $self->_fetch_profiles_list( $self->{gitsw_dir} );
    my %profiles;
    $profiles{$_} = 1 for @$profiles;
    unless ( defined $profiles{$profile} ) {
        die "'$profile' does not exist.\n";
    }

    # Rewrite current profile state
    $self->_write_profile( $self->{gitsw_profile}, $profile );

    # Rewire the symlink
    my $config_from = $self->{git_config_file};
    my $config_to = catfile( $self->{gitsw_dir}, $profile, 'config' );
    $self->_remove_already_exist_file($config_from);
    symlink $config_to, $config_from or die "$!\n";
}

sub create {
    my ( $self, $profile ) = @_;

    unless ($profile) {
        $self->_die_if_not_enough_args('create');
    }

    my $profile_path = catfile( $self->{gitsw_dir}, $profile );
    my $status = mkpath( catfile($profile_path) );
    unless ($status) {
        die "'$profile' already exists.\n";
    }

    my ( $name, $email ) = $self->_ask_user_data();

    my $default_config =
      Config::Simple->new( catfile( $self->{gitsw_dir}, 'default', 'config' ) );
    my $new_config = Config::Simple->new( syntax => 'ini' );
    $new_config->param(
        -block  => 'core',
        -values => $default_config->param( -block => 'core' ),
    );
    $new_config->param(
        -block  => 'user',
        -values => {
            'name'  => $name,
            'email' => $email,
        },
    );
    $new_config->write( catfile( $profile_path, 'config' ) );
}

sub _write_profile {
    my ( $self, $file, $profile ) = @_;

    open my $fh, '>', $file;
    print $fh $profile;
    close $fh;
}

sub _remove_already_exist_file {
    my ( $self, $file ) = @_;

    if ( -e $file || -l $file ) {
        unlink $file or die "$!\n";
    }
}

sub _die_if_not_enough_args {
    my ( $self, $command ) = @_;

    die "Please specify the profile name\n"
      . "Usage: \$ gitsw $command [profile name]\n";
}

sub _fetch_profiles_list {
    my ( $self, $path ) = @_;

    opendir my $dh, $path or die "Cannot open $path: $!\n";
    my @directories =
      grep { $_ !~ /^\.\.?$/ && -d catfile( $path, $_ ) } readdir($dh);
    close $dh;

    return \@directories;
}

sub _ask_user_data {
    my ($self) = @_;

    print 'User Name []: ';
    my $name = <STDIN>;

    print 'User Email []: ';
    my $email = <STDIN>;

    return $name, $email;
}

sub _has_already_initialized {
    my ($self) = @_;

    my $default_config_file = catfile($self->{gitsw_dir}, 'default', 'config');
    my $profile_file        = catfile($self->{gitsw_dir}, '.gitsw_profile');
    unless (-f $default_config_file && -f $profile_file) {
        die "Please initialize first!\n";
    }
}
1;
__END__

=encoding utf8

=head1 NAME

App::GitSw - Profile (config) switcher for Git


=head1 VERSION

This document describes App::GitSw version 0.0.1


=head1 SYNOPSIS

    $ gitsw [command] ([argument(s)])

    Commands:
        init                   Initialize the environment
        list                   Show the Git profiles
        create [profile name]  Create a empty Git profile
        switch [profile name]  Switch to the specified Git profile

    Example:
        $ gitsw init           # Initialize
        $ gitsw list           # Show profiles list
        $ gitsw create scott   # Create the Git profile of "scott"
        $ gitsw switch scott   # Switch the Git profile to "scott"


=head1 DESCRIPTION

gitsw is the profile (config) switcher for Git.

This application can switch each profiles and create profiles.


=head1 DEPENDENCIES

Config::Simple (version 4.58 or later)

Test::Exception (version 0.31 or later)

Test::File (version 1.34 or later)

Test::MockObject::Extends (version 1.20120301 or later)


=head1 CONFIGURATION AND ENVIRONMENT

This application requires Git (version 1.7.9 or later).


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
