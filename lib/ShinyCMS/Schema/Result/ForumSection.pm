use utf8;
package ShinyCMS::Schema::Result::ForumSection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ForumSection

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<forum_section>

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

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

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
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<forum_section_url_name>

=over 4

=item * L</url_name>

=back

=cut

__PACKAGE__->add_unique_constraint("forum_section_url_name", ["url_name"]);

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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-08 18:49:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FwYMQAk45WYoNZK7qYMyxA


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

