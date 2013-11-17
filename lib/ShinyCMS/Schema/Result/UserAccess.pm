use utf8;
package ShinyCMS::Schema::Result::UserAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::UserAccess

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

=head1 TABLE: C<user_access>

=cut

__PACKAGE__->table("user_access");

=head1 ACCESSORS

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 access

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 subscription_id

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 recurring

  data_type: 'integer'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "access",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subscription_id",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "recurring",
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

=item * L</user>

=item * L</access>

=back

=cut

__PACKAGE__->set_primary_key("user", "access");

=head1 RELATIONS

=head2 access

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Access>

=cut

__PACKAGE__->belongs_to(
  "access",
  "ShinyCMS::Schema::Result::Access",
  { id => "access" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 user

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ShinyCMS::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-11 19:48:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D/oYaXOzqRVMwfEnoPzSZg



# EOF
__PACKAGE__->meta->make_immutable;
1;

