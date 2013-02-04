package ShinyCMS::Controller::Shop::Basket;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Shop::Basket

=head1 DESCRIPTION

Controller for ShinyCMS shop basket.

=head1 METHODS

=cut


=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained('/base') : PathPart('shop/basket') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash( controller => 'Shop::Basket' );
}


=head2 view_basket

Display the basket contents

=cut

sub view_basket : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Try to make sure people can't fake a session ID and access another user's 
	# basket  (TODO: ask #catalyst if I need to handle this explicitly or if 
	# the Session Plugin will protect me from spoofing anyway)
	my $conditions = {
		session => $c->sessionid,
		user    => undef,
	};
	$conditions->{ user } = $c->user->id if $c->user_exists;
	
	my $basket_contents = $c->model('DB::Basket')->search(
#		{
#			session => $c->sessionid,
#		},
		$conditions,
		{
			join     => 'basket_items',
			prefetch => 'basket_items',
		}
	);
	
	$c->stash( basket_contents => $basket_contents );
}


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

1;

