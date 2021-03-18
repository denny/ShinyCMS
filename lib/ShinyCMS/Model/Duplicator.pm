package ShinyCMS::Model::Duplicator;

use Moose;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

use Carp;

extends qw/ Catalyst::Model /;

=head1 NAME

ShinyCMS::Model::Duplicator

=head1 DESCRIPTION

Clone ShinyCMS resources between two ShinyCMS databases - including
any essential related data (e.g. template elements with templates).

=head1 SYNOPSIS

	my $boink = ShinyCMS::Model::Duplicator->new({
		source_db      => < DBIC Schema >,
		destination_db => < DBIC Schema >,
		verbose        => 1
	});

	$boink->source_item( $dbic_result );
	# or
	$boink->set_source_item( 'CmsTemplate', $template_id );

	say $boink->clone->result;

=cut

has source_db => (
	is      => 'ro',
	default => undef
);

has destination_db => (
	is      => 'ro',
	default => undef
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

If you don't want to fetch a DBIC object to be cloned and pass that in,
you can pass its model name and ID instead to this method instead.

	$duplicator->set_source_item({
		item_type => 'CmsTemplate',
		item_id   => 123,
	});

=cut

sub set_source_item {
	my( $self, $item_type, $item_id ) = @_;

 	croak( 'set_source_item requires item_type and item_id' ) unless $item_type and $item_id;

	$self->{ source_item } = $self->source_db->resultset( $item_type )->find( $item_id );

	$self->add_error( $item_type .' #'. $item_id .' not found' ) unless $self->{ source_item };

	return $self;
}


sub result {
	my( $self ) = @_;

	return $self->error_message if $self->has_errors;

	return 'Duplicator cloned item to ID: '. $self->cloned_item->id ."\n";
}


# Private methods

sub not_ready_to_clone {
	my( $self ) = @_;

	$self->add_error( 'Destination database not specified.' ) unless $self->destination_db;
	$self->add_error( 'Source database not specified.'      ) unless $self->source_db;
	$self->add_error( 'Source item not specified.'          ) unless $self->source_item;

	return $self->has_errors;
}


sub create_cloned_item {
	my( $self ) = @_;

	my %source_data = $self->source_item->get_columns;
	delete $source_data{ id };

	$self->cloned_item(
		$self->destination_db->resultset( item_type( $self->source_item ) )->create( \%source_data )
	);

	my @elements = item_elements( $self->source_item )->all;
	$self->create_cloned_children( $self->cloned_item, \@elements );

	return $self;
}


sub create_cloned_children {
	my( $self, $cloned_item, $source_children ) = @_;

	foreach my $source_child ( @$source_children ) {
		my %source_data = $source_child->get_columns;
		delete $source_data{ id };

		item_elements( $cloned_item )->create( \%source_data );
	}

	return $cloned_item;
}

# Give us the correct elements stack for each item type
sub item_elements {
	my( $item ) = @_;

	my $type = item_type( $item );

	return $item->cms_page_elements          if $type eq 'CmsPage';
	return $item->cms_template_elements      if $type eq 'CmsTemplate';
	return $item->shop_item_elements         if $type eq 'ShopItem';
	return $item->shop_product_type_elements if $type eq 'ShopProductType';
}

# Turn 'ShinyCMS::Schema::Result::ShopItem' into 'ShopItem'
sub item_type {
	my( $item ) = @_;

	return substr( $item->result_class, 26 );
}


sub has_errors {
	my( $self ) = @_;

	return 1 if scalar( @{ $self->errors } ) > 0;
	return 0;
}

sub add_error {
	my( $self, $error_message ) = @_;

	push @{$self->errors}, $error_message;

	return;
}

sub error_message {
	my( $self ) = @_;

	return unless $self->has_errors;

	my $error_message = "Duplicator errors:\n";

	foreach my $error ( @{$self->errors} ) {
		$error_message .= "  $error\n";
	}

	return $error_message;
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
