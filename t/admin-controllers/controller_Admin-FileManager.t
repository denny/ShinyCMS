# ===================================================================
# File:		t/admin-controllers/controller_Admin-FileManager.t
# Project:	ShinyCMS
# Purpose:	Tests for file manager admin features
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $filemanager = create_test_admin( 'filemanager', 'CMS Page Editor', 'File Admin' );

my $t = login_test_admin( 'filemanager', 'filemanager' )
    or die 'Failed to log in as filemanager';

$t->get_ok(
    '/admin',
    'Fetch admin area'
);
# Upload a new file
$t->follow_link_ok(
    { text => 'Upload file' },
    'Follow link to file upload page'
);
$t->title_is(
	'Upload a file - ShinyCMS',
	'Reached file upload page'
);
$t->submit_form_ok({
    form_id => 'upload_file',
    fields => {
        upload => 'README.md'
    }},
    'Submitted file upload form'
);
# View list of CMS-uploaded files
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of CMS-uploaded files in admin area'
);
$t->content_contains(
    'README.md',
    'Verified that file was uploaded'
);
# TODO: Delete a CMS-uploaded file (feature not implemented yet!)
# Reload the file manager admin area to give the index() method some exercise
$t->get_ok(
    '/admin/filemanager',
    'Fetch file manager admin area one last time'
);
$t->title_is(
	'File Manager - ShinyCMS',
	'Reloaded file manager admin area via index method (yay, test coverage)'
);

remove_test_admin( $filemanager );

done_testing();
