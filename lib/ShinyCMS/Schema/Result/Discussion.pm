package ShinyCMS::Schema::Result::Discussion;

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

ShinyCMS::Schema::Result::Discussion

=cut

__PACKAGE__->table("discussion");

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
  default_value: 'BlogPost'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "resource_type",
  {
    data_type => "varchar",
    default_value => "BlogPost",
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 blog_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "ShinyCMS::Schema::Result::BlogPost",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 comments

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ShinyCMS::Schema::Result::Comment",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-14 16:15:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EqIZ3nvsUULPU6YTqZo/Zg


__PACKAGE__->has_many(
	"comments",
	"ShinyCMS::Schema::Result::Comment",
	{ "foreign.discussion" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);


sub get_thread {
	my ( $self, $parent ) = @_;
	
	# Get the top-level comments from the db
	my @comments = $self->comments->search({
		discussion => $self->id,
		parent => $parent,
	});

	# Build up the thread
	foreach my $comment ( @comments ) {
		$comment->{ children } = $self->get_thread( $comment->id );
	}
	
	return \@comments;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

