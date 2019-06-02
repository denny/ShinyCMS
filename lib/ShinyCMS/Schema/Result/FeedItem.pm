use utf8;
package ShinyCMS::Schema::Result::FeedItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::FeedItem

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

=head1 TABLE: C<feed_item>

=cut

__PACKAGE__->table("feed_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 feed

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 1

=head2 posted

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "feed",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "body",
  { data_type => "text", is_nullable => 1 },
  "posted",
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

=head2 feed

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Feed>

=cut

__PACKAGE__->belongs_to(
  "feed",
  "ShinyCMS::Schema::Result::Feed",
  { id => "feed" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7VHpn0xKzAfetNuo1IzS4w


=head2 teaser

Return the specified number of leading paragraphs from the body text

=cut

sub teaser {
	my ( $self, $count ) = @_;

	$count ||= 1;

	my @paragraphs;
	my $uses_br;
	if ( $self->body =~ m{<br />\s*?<br />} ) {
		@paragraphs = split /<br \/>\s*?<br \/>/, $self->body;
		$uses_br = 1;
	}
	else {
		@paragraphs = split '</p>', $self->body;
	}

	my $teaser = '';
	my $i = 1;
	foreach my $paragraph ( @paragraphs ) {
		$teaser .= $paragraph .'<br /><br />' if $uses_br;
		$teaser .= $paragraph .'</p>'     unless $uses_br;
		last if $i++ >= $count;
	}

	return $teaser;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

