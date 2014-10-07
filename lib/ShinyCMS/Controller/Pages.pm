package ShinyCMS::Controller::Pages;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Pages

=head1 DESCRIPTION

Controller for ShinyCMS CMS pages.

=cut


has page_prefix => (
	isa     => Str,
	is      => 'ro',
	default => 'pages',
);


=head1 METHODS

=cut


=head2 base

Set up path for content pages.

=cut

sub base : Chained( '/base' ) : PathPart( 'pages' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ controller } = 'Pages';
}


=head2 index

Display the default page if no page is specified.

=cut

sub index : Path : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $captures = [ $self->default_section( $c ), $self->default_page( $c ) ];
	$c->go( 'view_page', $captures, [] );
}


=head2 default_section

Return the default section.

=cut

sub default_section {
	my ( $self, $c ) = @_;
	
	# TODO: allow CMS Admins to configure this
	$c->stash->{ section } = $c->model( 'DB::CmsSection' )->first;
	
	# Skip to 'no data yet' page if no sections found in database
	$c->detach( 'no_page_data' ) unless $c->stash->{ section };
	
	# Return the default section
	return $c->stash->{ section }->url_name;
}


=head2 default_page

Return the default page.

=cut

sub default_page {
	my ( $self, $c ) = @_;
	
	if ( $c->stash->{ section }->default_page ) {
		# Return the default page for this section, if one is set
		return $c->stash->{ section }->default_page->url_name;
	}
	else {
		# TODO: Handle if section exists but has no pages
		
		# Return the first page added to the default section
		return $c->stash->{ section }->cms_pages->first->url_name;
	}
}


=head2 no_page_data

Return a helpful error page if database is unpopulated

=cut

sub no_page_data : Private {
	my ( $self, $c ) = @_;
	
	$c->response->body( 
		'<p>This is a ShinyCMS website.</p>'.
		
		'<p>If you are the site admin, please add some content in the '.
		'<a href="/admin">admin</a> area (see the docs/Getting-Started file '.
		'for hints).</p>'.
		
		'<p>If you are just looking, please come back later and hopefully '.
		'this site will have some content by then!</p>'
	);
}


=head2 build_menu

Build the menu data structure for the Pages section.

=cut

sub build_menu : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build up menu structure
	my $menu_items = [];
	my @sections = $c->model('DB::CmsSection')->search(
		{
			menu_position => { '!=' => undef },
			hidden        => 0,
		},
		{
			order_by => 'menu_position',
		},
	);
	foreach my $section ( @sections ) {
		push( @$menu_items, {
			name     => $section->name,
			url_name => $section->url_name,
			link     => '/'. $self->page_prefix .'/'. $section->url_name,
			pages    => [],
		});
		my @pages = $section->cms_pages->search(
			{
				menu_position => { '!=' => undef },
				hidden        => 0,
			},
			{
				order_by => 'menu_position'
			},
		);
		foreach my $page ( @pages ) {
			push( @{ $menu_items->[-1]->{ pages } }, {
				name     => $page->name,
				url_name => $page->url_name,
				link     => '/'. $self->page_prefix .'/'. $section->url_name .'/'. $page->url_name,
			} );
		}
	}
	return $menu_items;
}


=head2 get_section

Fetch the section and stash it.

=cut

sub get_section : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $section ) = @_;
	
	# Get the section
	$c->stash->{ section } = $c->model( 'DB::CmsSection' )->find({
		url_name => $section,
		hidden   => 0,
	});
	
	# 404 handler
#	$c->detach( 'get_root_page', \@_ ) unless $c->stash->{ section };
	$c->detach( 'Root', 'default' ) unless $c->stash->{ section };
}


=head2 get_section_page

Fetch the page for the appropriate section, and stash it.

=cut

sub get_section_page : Chained( 'get_section' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $page ) = @_;
	
	my $section = $c->stash->{ section };
	
	# get the default page if none is specified
	$page ||= $section->default_page;
	
	my $options = { url_name => $page };
	$options->{ hidden } = 0 unless $c->action eq 'pages/preview' 
		and $c->user->has_role( 'CMS Page Editor' );
	
	$c->stash->{ page } = $section->cms_pages->search( $options )->single;
	
	# 404 handler
	$c->detach( 'Root', 'default' ) unless $c->stash->{ page };
}


=head2 get_root_page

Fetch a root-level page and stash it.

=cut

sub get_root_page : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $page ) = @_;
	
	# get the default page if none is specified
	$page ||= default_page();
	
	$c->stash->{ page } = $c->model( 'DB::CmsPage' )->find({
		url_name => $page,
		section  => undef,
		hidden   => 0,
	});
	
	# 404 handler
	$c->detach( 'Root', 'default' ) unless $c->stash->{ page };
}


=head2 get_page

Fetch the page elements and stash them.

=cut

#sub get_page : Chained( 'get_root_page' ) : PathPart( '' ) : CaptureArgs( 0 ) {	# 1 level URLs - /pages/bar
sub get_page : Chained( 'get_section_page' ) : PathPart( '' ) : CaptureArgs( 0 ) {	# 2 level URLs - /pages/foo/bar
	my ( $self, $c ) = @_;
	
	# Get page elements
	my @elements = $c->model( 'DB::CmsPageElement' )->search( {
		page => $c->stash->{ page }->id,
	} );
	$c->stash->{ page_elements } = \@elements;
	
	# Build up 'elements' structure for use in cms-templates
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
}


=head2 preview

Preview a page.

=cut

sub preview : Chained( 'get_page' ) PathPart( 'preview' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to preview CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action => 'preview page edits', 
		role   => 'CMS Page Editor',
	});
	
	# Extract page details from form
	my $new_details = {
		name     => $c->request->param('name'    ) || 'No page name given',
		url_name => $c->request->param('url_name') || 'No url_name given',
		section  => $c->request->param('section' ) || undef,
	};
	
	# Extract page elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'name'    } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
		}
	}
	# And set them up for insertion into the preview page
	my $new_elements = {};
	foreach my $key ( keys %$elements ) {
		$new_elements->{ $elements->{ $key }->{ name } } = $elements->{ $key }->{ content };
	}
	
	# Set the TT template to use
	my $new_template;
	if ( $c->request->param('template') ) {
		$new_template = $c->model('DB::CmsTemplate')
			->find({ id => $c->request->param('template') })->template_file;
	}
	else {
		# TODO: get template details from db
		$new_template = $c->stash->{ page }->template->template_file;
	}
	
	# Over-ride everything
	$c->stash->{ page     } = $new_details;
	$c->stash->{ elements } = $new_elements;
	$c->stash->{ template } = 'pages/cms-templates/'. $new_template;
	$c->stash->{ preview  } = 'preview';
}


=head2 view_default_page

View the default page for a section if no page is specified.

=cut

sub view_default_page : Chained( 'get_section' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the default page for this section
	$c->stash->{ page }   = $c->stash->{ section }->default_page;
	$c->stash->{ page } ||= $c->stash->{ section }->cms_pages->first;
	
	# Get page elements
	my @elements = $c->model( 'DB::CmsPageElement' )->search({
		page => $c->stash->{ page }->id,
	});
	$c->stash->{ page_elements } = \@elements;
	
	# Build up 'elements' structure for use in cms-templates
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
	
	# Set the TT template to use
	$c->stash->{ template } = 'pages/cms-templates/'. $c->stash->{ page }->template->template_file;
}


=head2 view_page

View a page.

=cut

sub view_page : Chained( 'get_page' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{ template } = 'pages/cms-templates/'. $c->stash->{ page }->template->template_file;
}


=head2 get_feed_items

Get the specified number of items from the specified feed

=cut

sub get_feed_items {
	my ( $self, $c, $feed_name, $count ) = @_;
	
	$count ||= 10;
	
	my $feed = $c->model( 'DB::Feed' )->find({
		name => $feed_name,
	});
	
	my @items;
	if ( $feed ) {
		@items = $feed->feed_items->search(
			{},
			{
				order_by => { -desc => 'posted' },
				rows     => $count,
			},
		);
	}
	return \@items;
}


=head2 search

Search the site.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param('search') ) {
		my $search = $c->request->param('search');
		my @pages;
		my %page_hash;
		my @elements = $c->model('DB::CmsPageElement')->search({
			content => { 'LIKE', '%'.$search.'%'},
		});
		foreach my $element ( @elements ) {
			next if $element->page->hidden;
			# Pull out the matching search term and its immediate context
			$element->content =~ m/(.{0,50}$search.{0,50})/i;
			my $match = $1;
			# Tidy up and mark the truncation
			unless ( $match eq $element->content ) {
				$match =~ s/^\S+\s/... /;
				$match =~ s/\s\S+$/ .../;
			}
			# Add the match string to the page result
			$element->page->{ match } = $match;
			# Add the page to a de-duping hash
			$page_hash{ $element->page->url_name } = $element->page;
		}
		# Push the de-duped pages onto the results array
		foreach my $page ( keys %page_hash ) {
			push @pages, $page_hash{ $page };
		}
		$c->stash->{ page_results } = \@pages;
	}
}



=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2014 Shiny Ideas (www.shinyideas.co.uk).

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

