# ===================================================================
# File:		  t/lib/lib_Duplicator.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS::Duplicator
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2021 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'ShinyCMS::Model::DB'  }
BEGIN { use_ok 'ShinyCMS::Schema'     }
BEGIN { use_ok 'ShinyCMS::Duplicator' }

use lib 't/support';
require 'helpers.pl';  ## no critic

my $from_db = get_schema();
my $to_db   = get_schema();

my $duplicator = ShinyCMS::Duplicator->new({
	source_db      => $from_db,
	destination_db => $to_db
});

ok(
  defined $duplicator,
  'Created a ShinyCMS::Duplicator'
);
ok(
  $duplicator->not_ready_to_clone,
  'ShinyCMS::Duplicator is not ready to clone.'
);
ok(
  $duplicator->has_errors,
  'ShinyCMS::Duplicator has errors.'
);
ok(
  $duplicator->error_message =~ /Source item not specified/,
  'ShinyCMS::Duplicator error message includes "Source item not specified".'
);
ok(
  ( not defined $duplicator->success_message ),
  'ShinyCMS::Duplicator success message is blank while there are errors.'
);
ok(
  $duplicator->result eq $duplicator->error_message,
  'ShinyCMS::Duplicator->result returns the error message.'
);
ok(
  $duplicator->is_supported_type( 'CmsPage' ),
  'CmsPage is a supported item type.'
);

ok(
  ( not $duplicator->is_supported_type( 'TestFail' ) ),
  'TestFail is not a supported item type.'
);

my $source_item = $from_db->resultset( 'CmsPage' )->first;

ok(
  $duplicator->source_item( $source_item ),
  'Setting source item'
);

ok(
  $duplicator->ready_to_clone,
  'ShinyCMS::Duplicator is ready to clone'
);
ok(
  ( not $duplicator->has_errors ),
  'ShinyCMS::Duplicator does not have errors.'
);
ok(
  $duplicator->clone,
  'Cloning!'
);
ok(
  ( not $duplicator->has_errors ),
  'ShinyCMS::Duplicator does not have errors.'
);
ok(
  ( not defined $duplicator->error_message ),
  'ShinyCMS::Duplicator error message is blank now that there are no errors.'
);
ok(
  $duplicator->success_message =~ /Duplicator cloned a CmsPage/,
  'ShinyCMS::Duplicator success message includes "Duplicator cloned a CmsPage".'
);
ok(
  $duplicator->result eq $duplicator->success_message,
  'ShinyCMS::Duplicator->result returns the success message.'
);

$duplicator->cloned_item->elements->delete_all;
$duplicator->cloned_item->delete;

done_testing();
