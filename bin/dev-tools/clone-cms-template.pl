#!/usr/bin/env perl

# ===================================================================
# File:     bin/dev-tools/clone-cms-template.pl
# Project:  ShinyCMS
# Purpose:  Clone the data for a CMS Template (including its elements)
#           from one ShinyCMS site to another, using the Duplicator.
#
# Author:	Denny de la Haye <2021@denny.me>
# Copyright (c) 2009-2021 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use 5.010;

# Set this to 1 to get more output, 0 to get less
my $verbose = 1;

# Bail out early if no template ID was provided
my $template_id = $ARGV[0];
exit 'Please provide the ID of the template to be cloned.' unless $template_id;

# Work out where our local libs are, and load some of them
use Cwd;
my $shinyroot;
my $shinylib;
my $shinybinlib;
BEGIN {
    $shinyroot   =  cwd();
    $shinyroot   =~ s{ShinyCMS/.+}{ShinyCMS};
    $shinylib    =  $shinyroot.'/lib';
    $shinybinlib =  $shinyroot.'/bin/lib';
}
use lib $shinylib;
use lib $shinybinlib;

# Helper methods for getting source schema and config details
require 'helpers.pl';  ## no critic

# Load ShinyCMS modules
use ShinyCMS::Schema;
use ShinyCMS::Model::Duplicator;  # Cardboard box :)


# Get schema objects
my $source_db = get_schema();
my $destination_db = get_destination_schema();

# Create duplicator
my $duplicator = ShinyCMS::Model::Duplicator->new({
	source_db      => $source_db,
	destination_db => $destination_db,
	verbose        => $verbose
});

# Aim...
my $source_item = $source_db->resultset( 'CmsTemplate' )->find( $template_id );
$duplicator->source_item( $source_item );

# Fire!
say $duplicator->clone->result;


# Get schema object for destination database
# (CMS will need to provide this when integrated)
sub get_destination_schema {
	my $config = get_config();

	my $connect_info = $config->{ 'Model::Duplicator' }->{ destination_connect_info };

	return ShinyCMS::Schema->connect( $connect_info );
}
