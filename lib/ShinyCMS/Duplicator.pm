package ShinyCMS::Duplicator;

use Moose;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

use Carp;

=head1 NAME

ShinyCMS::Duplicator

=head1 DESCRIPTION

Clone ShinyCMS resources between two ShinyCMS databases - including
any essential related data (e.g. template elements with templates).

=head1 SYNOPSIS

	my $boink = ShinyCMS::Duplicator->new({
		source_db      => < DBIC Schema >,
		destination_db => < DBIC Schema >,
		verbose        => 1
	});

	$boink->source_item( $dbic_result );
	# or
	$boink->set_source_item( 'CmsTemplate', $template_id );

	say $boink->clone->result;

=cut

our @SUPPORTED_TYPES = ( 'CmsPage', 'CmsTemplate', 'ShopItem', 'ShopProductType' );

has source_db => (
	is       => 'ro',
	required => 1
);

has destination_db => (
	is       => 'ro',
	required => 1
);

has source_item => (
	is      => 'rw',
	default => undef
);

has cloned_item => (
	is      => 'rw',
	default => undef
);

has verbose => (
	isa     => Bool,
	is      => 'rw',
	default => 0,
);

has errors => (
	is      => 'rw',
	default => sub{ [] },
);


=head1 METHODS

=head2 clone

	$duplicator->clone;

=cut

sub clone {
	my( $self ) = @_;

	return $self if $self->not_ready_to_clone;

	$self->create_cloned_item;

	return $self;
}


=head2 set_source_item

Instead of directly setting ->source_item to a DBIC Result object,
you can pass its model name and ID instead to this method.

	$duplicator->set_source_item({
		item_type => 'CmsTemplate',
		item_id   => 123,
	});

=cut

sub set_source_item {
	my( $self, $item_type, $item_id ) = @_;

 	croak( 'set_source_item requires item_type and item_id' ) unless $item_type and $item_id;

	my $item = $self->source_db->resultset( $item_type )->find( $item_id );

	if ( $item ) {
		$self->source_item( $item );
		$self->cloned_item( undef );
	}
	else {
		$self->add_error( $item_type .' #'. $item_id .' not found' );
	}

	return $self;
}


=head2 is_supported_type

	my $supported = $duplicator->is_supported_type( 'CmsTemplate' );

=cut

sub is_supported_type {
	my( $self, $type ) = @_;

	return 1 if grep( /^$type$/, @SUPPORTED_TYPES );
	return 0;
}


=head2 result

Return a string containing success or error message(s) if appropriate.

=cut

sub result {
	my( $self ) = @_;

	return $self->error_message if $self->has_errors;

	return $self->success_message if $self->cloned_item;
}


=head2 has_errors

Returns true (1) if there are any errors in $self->errors

=cut

sub has_errors {
	my( $self ) = @_;

	return 1 if scalar( @{ $self->errors } ) > 0;
	return 0;
}


=head2 ready_to_clone

	my $is_ready = $duplicator->ready_to_clone;

=cut

sub ready_to_clone {
	my( $self ) = @_;

	$self->errors( [] );

	$self->add_error( 'Source item not specified.' ) unless $self->source_item;

	return ! $self->has_errors;
}

=head2 not_ready_to_clone

	my $not_ready = $duplicator->not_ready_to_clone;

=cut

sub not_ready_to_clone {
	my( $self ) = @_;

	return ! $self->ready_to_clone;
}

=head2 create_cloned_item

Does the actual cloning. Don't use this directly, use $duplicator->clone

=cut

sub create_cloned_item {
	my( $self ) = @_;

	my $source_data = data_to_clone( $self->source_item );
	my $item_type   = item_type( $self->source_item );

	my $clone = $self->destination_db->resultset( $item_type )->create( $source_data );

	$self->cloned_item( $clone );

	my @elements = $self->source_item->elements->all;
	$self->create_cloned_children( \@elements );

	return $self;
}

=head2 create_cloned_children

Clones the child data. Don't use this directly, use $duplicator->clone
to clone a top-level entity: CmsPage / ShopItem / etc

=cut

sub create_cloned_children {
	my( $self, $source_children ) = @_;

	foreach my $source_child ( @$source_children ) {
		my %source_data = $source_child->get_columns;

		delete $source_data{ id };
		delete $source_data{ parent_id_column( $source_child ) };

		$self->cloned_item->elements->create( \%source_data );
	}

	return $self;
}

=head2 data_to_clone

Creates a hash of the bits we want from a DBIC Result

=cut

sub data_to_clone {
	my( $source_item ) = @_;

	# Extract the column data from the Result object
	my %source_data = $source_item->get_columns;
	my $source_data = \%source_data;

	# Wipe the id column, so the destination database can set its own
	delete $source_data->{ id };

	# If the item has a url_name, attempt to avoid collisions by altering it
	$source_data = update_url_name( $source_data );

	return $source_data;
}

=head2 update_url_name

Munges the url_name param to try to avoid collisions

=cut

sub update_url_name {
	my( $source_data ) = @_;

	return $source_data unless defined $source_data->{ url_name };

	my $slug = $source_data->{ url_name };

	if ( $slug =~ m{-clone-\d+$} ) {
		$slug =~ m{-clone-(\d+)$};
		my $prev = $1;
		my $next = $prev + 1;
		$slug =~ s/-clone-\d+$/-clone-$next/;
	}
	elsif ( substr( $slug, -6 ) eq '-clone' ) {
		$slug .= '-2';
	}
	else {
		$slug .= '-clone';
	}

	$source_data->{ url_name } = $slug;

	return $source_data;
}

=head2 parent_id_column

Give us the name of the parent ID column for each item type

=cut

sub parent_id_column {
	my( $parent ) = @_;

	my $type = item_type( $parent );

	return 'page'         if $type eq 'CmsPageElement';
	return 'template'     if $type eq 'CmsTemplateElement';
	return 'item'         if $type eq 'ShopItemElement';
	return 'product_type' if $type eq 'ShopProductTypeElement';

	croak 'Failed to identify parent entity for '. $type;
}

=head2 item_type

Turn 'ShinyCMS::Schema::Result::ShopItem' into 'ShopItem'

=cut

sub item_type {
	my( $item ) = @_;

	my $name = $item->result_class;

	$name =~ s{ShinyCMS::Schema::Result::}{};
	$name =~ s{ShinyCMS::Model::DB::}{};

	return $name;
}


=head2 add_error

=cut

sub add_error {
	my( $self, $error_message ) = @_;

	push @{$self->errors}, $error_message;

	return;
}

=head2 error_message

=cut

sub error_message {
	my( $self ) = @_;

	return unless $self->has_errors;

	my $error_message = 'Duplicator errors:';

	foreach my $error ( @{$self->errors} ) {
		$error_message .= "\n  $error";
	}

	return $error_message;
}

=head2 success_message

=cut

sub success_message {
	my( $self ) = @_;

	return if $self->has_errors;

	my $type   = item_type( $self->source_item );
	my $old_id = $self->source_item->id;
	my $new_id = $self->cloned_item->id;

	return "Duplicator cloned a $type from ID $old_id to ID $new_id";
}


=head1 AUTHOR

Denny de la Haye <2021@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2021 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
