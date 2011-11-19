use utf8;
package ShinyCMS::Schema::Result::MailRecipient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::MailRecipient

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

=head1 TABLE: C<mail_recipient>

=cut

__PACKAGE__->table("mail_recipient");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list_recipients

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ListRecipient>

=cut

__PACKAGE__->has_many(
  "list_recipients",
  "ShinyCMS::Schema::Result::ListRecipient",
  { "foreign.recipient" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-11-19 02:30:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pbWc/Duc9rKL7o9PsDDqWg


__PACKAGE__->many_to_many( roles => 'list_recipients', 'mailing_list' );


# EOF
__PACKAGE__->meta->make_immutable;
1;

