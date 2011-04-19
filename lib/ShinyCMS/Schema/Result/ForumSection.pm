package ShinyCMS::Schema::Result::ForumSection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

ShinyCMS::Schema::Result::ForumSection

=cut

__PACKAGE__->table("forum_section");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 display_order

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "display_order",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 forums

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Forum>

=cut

__PACKAGE__->has_many(
  "forums",
  "ShinyCMS::Schema::Result::Forum",
  { "foreign.section" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-04-15 19:00:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GUK6myvBZBuQsQGCQj2aiQ


=head2 sorted_forums

Return associated forums in specified display order.

=cut

sub sorted_forums {
	my( $self ) = @_;
	return $self->forums->search(
		{},
		{ order_by => 'display_order' },
	);
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

