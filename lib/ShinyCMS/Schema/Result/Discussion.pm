package Reactant::Schema::Result::Discussion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("discussion");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "resource_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "resource_type",
  {
    data_type => "VARCHAR",
    default_value => "BlogPost",
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "blog_posts",
  "Reactant::Schema::Result::BlogPost",
  { "foreign.discussion" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 18:06:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S3nrWzzQ6bv9jCCUzj0AMg

__PACKAGE__->has_many(
  "comments",
  "Reactant::Schema::Result::Comment",
  { "foreign.discussion" => "self.id" },
);


sub get_thread {
    my ( $self, $parent ) = @_;
	
	# Get the top-level comments from the db
	my @comments = $self->comments->search({
		discussion => $self->id,
		parent     => $parent,
	});
	
	# Build up the thread
	foreach my $comment ( @comments ) {
		$comment->{ children } = $self->get_thread( $comment->id );
	}
	
	return \@comments;
}


# EOF
1;

