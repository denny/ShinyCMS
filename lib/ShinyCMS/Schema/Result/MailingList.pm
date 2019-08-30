use utf8;
package ShinyCMS::Schema::Result::MailingList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::MailingList

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

=head1 TABLE: C<mailing_list>

=cut

__PACKAGE__->table("mailing_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 user_can_sub

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 user_can_unsub

  data_type: 'tinyint'
  default_value: 1
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
  "user_can_sub",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
  "user_can_unsub",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
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

=head2 newsletters

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Newsletter>

=cut

__PACKAGE__->has_many(
  "newsletters",
  "ShinyCMS::Schema::Result::Newsletter",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 paid_lists

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PaidList>

=cut

__PACKAGE__->has_many(
  "paid_lists",
  "ShinyCMS::Schema::Result::PaidList",
  { "foreign.mailing_list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 subscriptions

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "ShinyCMS::Schema::Result::Subscription",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-08-27 21:11:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AcSkVjlRNGrw7TKM5z9bfw


__PACKAGE__->many_to_many( subscribers => 'subscriptions', 'recipient' );


# EOF
__PACKAGE__->meta->make_immutable;
1;

