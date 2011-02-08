package ShinyCMS::Schema::Result::Feed;

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

ShinyCMS::Schema::Result::Feed

=cut

__PACKAGE__->table("feed");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 last_checked

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
  "url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "last_checked",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 feed_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::FeedItem>

=cut

__PACKAGE__->has_many(
  "feed_items",
  "ShinyCMS::Schema::Result::FeedItem",
  { "foreign.feed" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-07 22:18:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6hg20Kn1qpL6wETi1DlJDA



# EOF
__PACKAGE__->meta->make_immutable;
1;

