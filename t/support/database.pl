# ===================================================================
# File:		t/support/database.pl
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

# Load local modules
use FindBin qw( $Bin );
use lib "$Bin/../lib";
use ShinyCMS::Schema;


# Store the schema object
my $schema;


=head1 METHODS

=head2 get_schema

Return a ShinyCMS::Schema object, after getting database connection details
and connecting to database if necessary.
    my $schema = get_schema();

=cut

sub get_schema {
    return $schema if $schema;

    # Get the database connection details from the config file
    my $env = '';
    $env = '_test' if $ENV{ SHINYCMS_TEST };
    my $config_file = $Bin . "/../../config/shinycms${env}.conf";
    my $reader = Config::General->new( $config_file );
    my %config = $reader->getall;

    # Get the database connection details and connect
    my $connect_info = $config{ 'Model::DB' }->{ connect_info };
    $schema = ShinyCMS::Schema->connect( $connect_info );
}


# EOF
1;
