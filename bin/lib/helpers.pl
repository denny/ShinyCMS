# ===================================================================
# File:	    bin/lib/helpers.pl
# Project:	ShinyCMS
# Purpose:	Helper method for making database connections in scripts
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

# Load CPAN modules
use Config::General;
use Cwd;

# Work out where the project root is, and hence where the project lib dir is
my $shinyroot;
my $shinylib;
BEGIN {
    $shinyroot =  cwd();
    $shinyroot =~ s{ShinyCMS/.+}{ShinyCMS};
    $shinylib  =  $shinyroot.'/lib';
}

# Load local modules
use lib $shinylib;
use ShinyCMS::Schema;


# Persistence
my $config;
my $schema;


=head1 METHODS

=head2 get_config

Return a hashref containing the app config (including any test config overrides)
    my $config = get_config();

=cut

sub get_config {
    return $config if $config;

    my $config_file = $shinyroot.'/config/shinycms.conf';
    my $reader = Config::General->new( $config_file );
    my %config = $reader->getall;

    if ( $ENV{ SHINYCMS_TEST } ) {
        my $test_config_file = $shinyroot.'/config/shinycms_test.conf';
        my $test_reader = Config::General->new( $test_config_file );
        my %test_config = $test_reader->getall;
        @config{ keys %test_config } = values %test_config;
    }

    $config = \%config;
    return $config;
}


=head2 get_schema

Return a ShinyCMS::Schema object, after getting database connection details
and connecting to database if necessary.
    my $schema = get_schema();

=cut

sub get_schema {
    return $schema if $schema;

    my $config = get_config();
    my $connect_info = $config->{ 'Model::DB' }->{ connect_info };

    $schema = ShinyCMS::Schema->connect( $connect_info );
    return $schema;
}


# EOF
1;
