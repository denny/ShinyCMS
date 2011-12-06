package ShinyCMS::Controller::Blog;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use XML::Feed;
use Encode;


=head1 NAME

ShinyCMS::Controller::Blog

=head1 DESCRIPTION

Controller for ShinyCMS blogs.

=head1 METHODS

=cut


=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/' ) : PathPart( 'blog' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the current date
	$c->stash->{ now } = DateTime->now;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Blog';
}


=head2 get_posts

Get a page's worth of posts

=cut

sub get_posts {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 get_posts_for_year

Get a year's worth of posts, broken down by months (for archive widget)

=cut

sub get_posts_for_year {
	my ( $self, $c, $year ) = @_;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			-and => [
				posted   => { '<=' => \'current_timestamp' },
				-nest    => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
			],
		},
		{
			order_by => { -desc => 'posted' },
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		unshift @$tagged_posts, $post;
	}
	
	my $by_months = {};
	foreach my $post ( @$tagged_posts ) {
		my $month = $post->posted->month;
		push @{ $by_months->{ $month } }, $post;
	}
	
	my $months = [];
	foreach my $month ( sort {$a<=>$b} keys %$by_months ) {
		push @$months, $by_months->{ $month };
	}
	
	return $months;
}


=head2 get_post

=cut

sub get_post {
	my ( $self, $c, $post_id ) = @_;
	
	return $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
}


=head2 get_tags

Get the tags for a post, or for the whole blog if no post specified

=cut

sub get_tags {
	my ( $self, $c, $post_id ) = @_;
	
	if ( $post_id ) {
		my $tagset = $c->model( 'DB::Tagset' )->find({
			resource_id   => $post_id,
			resource_type => 'BlogPost',
		});
		return $tagset->tag_list if $tagset;
	}
	else {
		my @tagsets = $c->model( 'DB::Tagset' )->search({
			resource_type => 'BlogPost',
		});
		my @taglist;
		foreach my $tagset ( @tagsets ) {
			push @taglist, @{ $tagset->tag_list };
		}
		my %taghash;
		foreach my $tag ( @taglist ) {
			$taghash{ $tag } = 1;
		}
		my @tags = keys %taghash;
		@tags = sort { lc $a cmp lc $b } @tags;
		return \@tags;
	}
	
	return;
}


=head2 get_tagged_posts

Get a page's worth of posts with a particular tag

=cut

sub get_tagged_posts {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'BlogPost';
		push @tagged, $tagset->get_column( 'resource_id' ),
	}
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			id       => { 'in' => \@tagged },
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 get_posts_by_author

Get a page's worth of posts by a particular author

=cut

sub get_posts_by_author {
	my ( $self, $c, $username, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			author   => $author->id,
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 view_posts

Display a page of blog posts.

=cut

sub view_posts : Chained( 'base' ) : PathPart( 'page' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Blog }->{ posts_per_page };
	
	my $posts = $self->get_posts( $c, $page, $count );
	
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ blog_posts } = $posts;
}


=head2 view_recent

Display recent blog posts.

=cut

sub view_recent : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'view_posts' );
}


=head2 view_tag

Display a page of blog posts with a particular tag.

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : OptionalArgs( 3 ) {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->go( 'view_recent' ) unless $tag;
	
	$page  ||= 1;
	$count ||= $c->config->{ Blog }->{ posts_per_page };
	
	my $posts = $self->get_tagged_posts( $c, $tag, $page, $count );
	
	$c->stash->{ tag        } = $tag;
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ blog_posts } = $posts;
	
	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_month

Display blog posts from a specified month.

=cut

sub view_month : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $year, $month ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my @blog_posts = $c->model( 'DB::BlogPost' )->search(
		-and => [
			posted => { '<=' => \'current_timestamp' },
			-nest  => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
			-nest  => \[ 'month(posted) = ?', [ plain_value => $month ] ],
		],
	);
	$c->stash->{ blog_posts } = \@blog_posts;
	
	my $one_month = DateTime::Duration->new( months => 1 );
	my $date = DateTime->new( year => $year, month => $month );
	my $prev = $date - $one_month;
	my $next = $date + $one_month;
	
	$c->stash->{ date      } = $date;
	$c->stash->{ prev      } = $prev;
	$c->stash->{ next      } = $next;
	$c->stash->{ prev_link } = $c->uri_for( $prev->year, $prev->month );
	$c->stash->{ next_link } = $c->uri_for( $next->year, $next->month );
	
	$c->stash->{ template  } = 'blog/view_posts.tt';
}


=head2 view_year

Display summary of blog posts in a year.

=cut

sub view_year : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $year ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ months } = $self->get_posts_for_year( $c, $year );
	$c->stash->{ year   } = $year;
}


=head2 view_posts_by_author

Display a page of blog posts by a particular author.

=cut

sub view_posts_by_author : Chained( 'base' ) : PathPart( 'author' ) : OptionalArgs( 3 ) {
	my ( $self, $c, $author, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Blog }->{ posts_per_page };
	
	my $posts = $self->get_posts_by_author( $c, $author, $page, $count );
	
	$c->stash->{ author     } = $author;
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ blog_posts } = $posts;
	
	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_post

View a specified blog post.

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	# Stash the post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->search({
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	})->first;
	
	unless ( $c->stash->{ blog_post } ) {
		$c->flash->{ error_msg } = 'Failed to find specified blog post.';
		$c->go( 'view_recent' );
	}
	
	$c->stash->{ year } = $year;  
	
	# Stash the tags
	$c->stash->{ blog_post }->{ tags } = $self->get_tags( $c, $c->stash->{ blog_post }->id );
}


# ==================== ( Admin features ) ====================

=head2 generate_atom_feed

Generate the atom feed.

=cut

sub generate_atom_feed {
	my ( $self, $c ) = @_;
	
	# Get the 10 most recent posts
	my $posts = $self->get_posts( $c, 1, 10 );
	
	my $now = DateTime->now;
	my $domain    = $c->config->{ domain    } || 'shinycms.org';
	my $site_name = $c->config->{ site_name } || 'ShinySite';
	
	my $feed = XML::Feed->new( 'Atom' );
	$feed->id(          'tag:'. $domain .',2010:blog' );
	$feed->self_link(   $c->uri_for( '/static', 'feeds', 'atom.xml' ) );
	$feed->link(        $c->uri_for( '/blog' )               );
	$feed->modified(    $now                                 );
	$feed->title(       $site_name                           );
	$feed->description( 'Recent blog posts from '.$site_name );
	
	# Process the entries
	foreach my $post ( @$posts ) {
		my $posted = $post->posted;
		$posted->set_time_zone( 'UTC' );
		
		my $url = $c->uri_for( '/blog', $posted->year, $posted->month, $post->url_title );
		my $id  = 'tag:'. $domain .',2010:blog:'. $posted->year .':'. $posted->month .':'. $post->url_title;
		
		my $author = $post->author->display_name || $post->author->username;
		
		my $entry = XML::Feed::Entry->new( 'Atom' );
		
		$entry->id(       $id          );
		$entry->link(     $url         );
		$entry->author(   $author      );
		$entry->modified( $posted      );
		$entry->title(    $post->title );
		$entry->content(  $post->body  );
		
		$feed->add_entry( $entry );
	}
	
	# Write feed to file
	my $xml  = $feed->as_xml;
	my $file = $c->path_to( 'root', 'static', 'feeds' ) .'/atom.xml';
	open my $fh, '>', $file or die "Failed to open atom.xml for writing: $!";
	print $fh $xml, "\n";
	close $fh;
}


=head2 admin_get_posts

Get the recent posts, including forward-dated ones

=cut

sub admin_get_posts {
	my ( $self, $c, $page, $count ) = @_;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	return \@posts;
}


=head2 list_posts

Lists all blog posts, for use in admin area.

=cut

sub list_posts : Chained( 'base' ) : PathPart( 'list' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	# Check to make sure user has the right to view the list of blog posts
	return 0 unless $self->user_exists_and_can($c, {
		action => 'view the list of blog posts', 
		role   => 'Blog Author',
	});
	
	$page  ||= 1;
	$count ||= 20;
	
	my $posts = $self->admin_get_posts( $c, $page, $count );
	
	$c->stash->{ blog_posts } = $posts;
}


=head2 add_post

Add a new blog post.

=cut

sub add_post : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add a blog post
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a blog post', 
		role     => 'Blog Author',
		redirect => '/blog',
	});
	
	# Find default comment setting and pass through
	$c->stash->{ comments_default_on } = 'YES' 
		if uc $c->config->{ Blog }->{ comments_default } eq 'YES';
	
	$c->stash->{ template } = 'blog/edit_post.tt';
}


=head2 add_post_do

Process adding a blog post.

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'add-post-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add a blog post
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a blog post', 
		role     => 'Blog Author',
		redirect => '/blog',
	});
	
	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;
	
	# TODO: catch and fix duplicate year/month/url_title combinations
	
	my $posted;
	if ( $c->request->param( 'posted_date' ) ) {
		$posted = $c->request->param( 'posted_date' ) .' '. $c->request->param( 'posted_time' );
	}
	
	# Add the post
	my $post = $c->model( 'DB::BlogPost' )->create({
		author    => $c->user->id,
		title     => $c->request->param( 'title' ) || undef,
		url_title => $url_title || undef,
		body      => $c->request->param( 'body'  ) || undef,
		blog      => 1,
		posted    => $posted,
	});
	
	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		$post->update({ discussion => $discussion->id });
	}
	
	# Process the tags
	if ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post added';
	
	# Rebuild the atom feed
	$c->forward( 'Blog', 'generate_atom_feed' );
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $post->id ) );
}


=head2 edit_post

Edit an existing blog post.

=cut

sub edit_post : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $post_id ) = @_;
	
	# Check to make sure user has the right to edit a blog post
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a blog post', 
		role     => 'Blog Author',
		redirect => '/blog',
	});
	
	# Stash the blog post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
	# Stash the tags
	$c->stash->{ blog_post_tags } = $self->get_tags( $c, $post_id );
}


=head2 edit_post_do

Process an update.

=cut

sub edit_post_do : Chained( 'base' ) : PathPart( 'edit-post-do' ) : Args( 1 ) {
	my ( $self, $c, $post_id ) = @_;
	
	# Check to make sure user has the right to edit a blog post
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a blog post', 
		role     => 'Blog Author',
		redirect => '/blog',
	});
	
	# Get the post
	my $post = $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $post->id,
		resource_type => 'BlogPost',
	});
	
	# Process deletions
	if ( defined $c->request->param( 'delete' ) && $c->request->param( 'delete' ) eq 'Delete' ) {
		$tagset->tags->delete if $tagset;
		$tagset->delete if $tagset;
		$post->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Post deleted';
		
		# Bounce to the list of posts
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}
	
	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;
	
	# TODO: catch and fix duplicate year/month/url_title combinations
	
	my $posted = $c->request->param( 'posted_date' ) .' '. $c->request->param( 'posted_time' );
	
	# Perform the update
	$post->update({
		title     => $c->request->param( 'title' ) || undef,
		url_title => $url_title || undef,
		body      => $c->request->param( 'body'  ) || undef,
		posted    => $posted,
	} );
	
	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) and not $post->discussion ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		$post->update({ discussion => $discussion->id });
	}
	# Disconnect the related discussion thread, if requested
	# (leaves it orphaned, rather than deleting it)
	elsif ( $post->discussion and not $c->request->param( 'allow_comments' ) ) {
		$post->update({ discussion => undef });
	}
	
	# Process the tags
	if ( $tagset ) {
		my $tags = $tagset->tags;
		$tags->delete;
		if ( $c->request->param('tags') ) {
			my @tags = sort split /\s*,\s*/, $c->request->param('tags');
			foreach my $tag ( @tags ) {
				$tagset->tags->create({
					tag => $tag,
				});
			}
		}
		else {
			$tagset->delete;
		}
	}
	elsif ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post updated';
	
	# Rebuild the atom feed
	$c->forward( 'Blog', 'generate_atom_feed' );
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $post_id ) );
}


=head2 search

Search the news section.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $blog_posts = [];
		my @results = $c->model( 'DB::BlogPost' )->search({
			-and => [
				posted    => { '<=' => \'current_timestamp' },
				-or => [
					title => { 'LIKE', '%'.$search.'%'},
					body  => { 'LIKE', '%'.$search.'%'},
				],
			],
		});
		foreach my $result ( @results ) {
			# Pull out the matching search term and its immediate context
			my $match = '';
			if ( $result->title =~ m/(.{0,50}$search.{0,50})/is ) {
				$match = $1;
			}
			elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/is ) {
				$match = $1;
			}
			# Tidy up and mark the truncation
			unless ( $match eq $result->title or $match eq $result->body ) {
				$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
				$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
			}
			if ( $match eq $result->title ) {
				$match = substr $result->body, 0, 100;
				$match =~ s/\s\S+\s?$/ .../;
			}
			# Add the match string to the result
			$result->{ match } = $match;
			
			# Push the result onto the results array
			push @$blog_posts, $result;
		}
		$c->stash->{ blog_results } = $blog_posts;
	}
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

