package ShinyCMS::Schema::Result::NewsItem;

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

ShinyCMS::Schema::Result::NewsItem

=cut

__PACKAGE__->table("news_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 posted

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "posted",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "ShinyCMS::Schema::Result::User",
  { id => "author" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DqaH6gmhMhPOG4kjJLS2EQ


=head2 teaser

Return the specified number of leading paragraphs from the body text

=cut

sub teaser {
	my ( $self, $count ) = @_;
	
	$count ||= 1;
	
	my @paragraphs = split '</p>', $self->body;
	
	my $teaser = '';
	my $i = 1;
	foreach my $paragraph ( @paragraphs ) {
		$teaser .= $paragraph .'</p>';
		last if $i++ >= $count;
	}
	
	return $teaser;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

