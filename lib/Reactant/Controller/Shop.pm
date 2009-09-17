package Reactant::Controller::Shop;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

Reactant::Controller::Shop

=head1 DESCRIPTION

Main controller for Reactant's online shop functionality.

=head1 METHODS

=cut


=head2 index

Not used at present.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
}


=head2 base

Currently this just provides the base part of the path.

=cut

sub base : Chained('/') : PathPart('shop') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# ...
}


=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained('base') : PathPart('item') : CaptureArgs(1) {
	my ( $self, $c, $item_id ) = @_;
	
	if ( $item_id =~ /\D/ ) {
		# non-numeric identifier (product code)
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { code => $item_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { id => $item_id } );
	}
	
	# TODO: 404 handler
	die "Item $item_id not found" unless $c->stash->{ item };
}


sub view : Chained('get_item') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
}


sub edit : Chained('get_item') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
}


sub edit_do : Chained('get_item') : PathPart('edit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: Check to see if user is allowed to edit items
	# ...
	
	# Extract item details from form
	my $details = {};
	# ...
	
	# Update item
	my $item = $c->model('DB::ShopItem')->find({
					id => $c->stash->{ item }->id,
				})->update( $details );
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/shop/'. $c->stash->{ item }->id .'/edit' );
}



=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

