use utf8;
package ShinyCMS::Schema::Result::Tagset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Tagset

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

=head1 TABLE: C<tagset>

=cut

__PACKAGE__->table("tagset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 resource_id

  data_type: 'integer'
  is_nullable: 0

=head2 resource_type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "resource_type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
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

=head1 RELATIONS

=head2 tags

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
  "tags",
  "ShinyCMS::Schema::Result::Tag",
  { "foreign.tagset" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-03-30 16:56:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OgZpuJqCOi/AkrcLMJR1OA


=head2 tag_list

Return a list of the tags in this set.

=cut

sub tag_list {
	  my ( $self ) = @_;

    my @tags = $self->tags->get_column( 'tag' )->all;

    @tags = sort { lc $a cmp lc $b } @tags;

    return \@tags;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
