use utf8;
package ShinyCMS::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-11-19 02:30:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bCLkzl6sdeH6UVirNy0yew



=head1 NAME

ShinyCMS::Schema

=head1 SYNOPSIS

See L<ShinyCMS>

=head1 DESCRIPTION

Catalyst DBIC Schema

=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut



# EOF
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

