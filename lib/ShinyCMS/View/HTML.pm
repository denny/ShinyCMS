package ShinyCMS::View::HTML;

use Moose;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
	TEMPLATE_EXTENSION => '.tt',
	WRAPPER  => 'wrapper.tt',
);

=head1 NAME

ShinyCMS::View::HTML

=head1 DESCRIPTION

TT View for ShinyCMS. 

=head1 SEE ALSO

L<ShinyCMS>

=head1 AUTHOR

Denny de la Haye <2009@denny.me>

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

