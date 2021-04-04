use utf8;
package ShinyCMS::Schema::Result::NewsItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::NewsItem

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

=head1 TABLE: C<news_item>

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

=head2 related_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 posted

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
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
  "related_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
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

=head2 author

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "ShinyCMS::Schema::Result::User",
  { id => "author" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uJTB4osHLT6swvrcvL604Q


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


=head2 teaser_image

Return the Nth image link from the body text

=cut

sub teaser_image {
	my ( $self, $n ) = @_;

	$n = $n ? $n : 1;

	use HTML::TreeBuilder;
	my $tree = HTML::TreeBuilder->new;
	$tree->parse_content( $self->body );

	my @imgs = $tree->look_down(
		_tag => 'img',
	);
	my @srcs;
	foreach my $img ( @imgs ) {
		push @srcs, $img->attr( 'src' );
	}

	$tree->delete;

	return $srcs[$n-1];
}


=head2 tagset

Return the tagset for this news item

=cut

sub tagset {
    my ( $self ) = @_;

    $self->result_source->schema->resultset( 'Tagset' )->find_or_create({
        resource_type => 'NewsItem',
        resource_id   => $self->id,
        hidden        => $self->hidden,
    });
}


=head2 tags

Return the tag list for this news item

=cut

sub tags {
    my ( $self ) = @_;

    return $self->tagset->tag_list;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
