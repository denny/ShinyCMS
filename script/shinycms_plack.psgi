#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use ShinyCMS;

my $app = ShinyCMS->psgi_app( @_ );

