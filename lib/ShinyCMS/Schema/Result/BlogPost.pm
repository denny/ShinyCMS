use utf8;
package ShinyCMS::Schema::Result::BlogPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::BlogPost

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

=head1 TABLE: C<blog_post>

=cut

__PACKAGE__->table("blog_post");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 120

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 120

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 blog

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 posted

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "blog",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "posted",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 blog

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Blog>

=cut

__PACKAGE__->belongs_to(
  "blog",
  "ShinyCMS::Schema::Result::Blog",
  { id => "blog" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 discussion

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-18 15:24:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KBP8xLjzsuZsXgOdgE05BA


=head2 comment_count

Return the total number of comments on this post

=cut

sub comment_count {
	my ( $self ) = @_;

	return 0 unless $self->discussion;
	return 0 + $self->discussion->comments->count;
}


=head2 teaser

Return the specified number of leading paragraphs from the body text

=cut

sub teaser {
	my ( $self, $count ) = @_;

	$count = $count ? $count : 1;

	my @paragraphs = split '</p>', $self->body;

	my $teaser = '';
	my $i = 1;
	foreach my $paragraph ( @paragraphs ) {
		next unless $paragraph =~ m/\S/;
		$teaser .= $paragraph . '</p>';
		last if $i++ >= $count;
	}

	return $teaser;
}


=head2 tagset

Return the tagset for this blog post

=cut

sub tagset {
    my ( $self ) = @_;

    $self->result_source->schema->resultset( 'Tagset' )->find_or_create({
        resource_type => 'BlogPost',
        resource_id   => $self->id,
        hidden        => $self->hidden,
    });
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
