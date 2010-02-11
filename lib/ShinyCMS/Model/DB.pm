package ShinyCMS::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

# MySQL equivalent of 'use strict; use warnings;'
# In particular, prevents a 'NOT NULL' ENUM being silently set to NULL when 
# an invalid value is entered (and throws an error instead).  Yay, sanity!
my $options = {
	on_connect_do => [
		q/SET SQL_MODE = 'TRADITIONAL'/, 
		q/SET SQL_AUTO_IS_NULL = 0/
	]
};


__PACKAGE__->config(
    schema_class => 'ShinyCMS::Schema',
    connect_info => [
        'dbi:mysql:reactant',
        'react',
        'ant',
        { AutoCommit => 1 },
        $options,
    ],
);


=head1 NAME

ShinyCMS::Model::DB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<ShinyCMS>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<ShinyCMS::Schema>

=head1 AUTHOR

Denny de la Haye <2010@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

1;

