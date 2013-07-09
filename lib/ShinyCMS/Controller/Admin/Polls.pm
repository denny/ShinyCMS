package ShinyCMS::Controller::Admin::Polls;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Polls

=head1 DESCRIPTION

Controller for ShinyCMS poll admin features.

=head1 METHODS

=cut



=head2 base

Base method, sets up path.

=cut

sub base : PathPart( 'admin/polls' ) : Chained( '/' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Polls';
}


# TODO: everything!



=head1 AUTHOR

Denny de la Haye <2013@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2013 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

