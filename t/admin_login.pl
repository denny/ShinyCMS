# ===================================================================
# File:		t/admin_login.pl
# Project:	ShinyCMS
# Purpose:	Utility lib for use in admin controller tests
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::WWW::Mechanize::Catalyst;

sub admin_login {
    my $mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );
    $mech->get( '/admin' );
    $mech->submit_form(
    	form_id => 'login',
        fields => {
    		username => 'admin',
        	password => 'changeme'
    	},
    );
    my $link = $mech->find_link( text => 'Logout' );
    return $mech if $link;
    return;
}

# EOF
1;
