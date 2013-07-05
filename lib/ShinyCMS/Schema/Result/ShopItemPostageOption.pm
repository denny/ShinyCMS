use utf8;
package ShinyCMS::Schema::Result::ShopItemPostageOption;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ShopItemPostageOption

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

=head1 TABLE: C<shop_item_postage_option>

=cut

__PACKAGE__->table("shop_item_postage_option");

=head1 ACCESSORS

=head2 item

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 postage

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "item",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "postage",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

=item * L</item>

=item * L</postage>

=back

=cut

__PACKAGE__->set_primary_key("item", "postage");

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopItem>

=cut

__PACKAGE__->belongs_to(
  "item",
  "ShinyCMS::Schema::Result::ShopItem",
  { id => "item" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 postage

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PostageOption>

=cut

__PACKAGE__->belongs_to(
  "postage",
  "ShinyCMS::Schema::Result::PostageOption",
  { id => "postage" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c/1RjLOrMDJ2SyJpVUkUtw



# EOF
__PACKAGE__->meta->make_immutable;
1;

