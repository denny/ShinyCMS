package ShinyCMS::Controller::Pages;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Pages

=head1 DESCRIPTION

Controller for ShinyCMS CMS pages.

=head1 METHODS

=cut


# Leading part of URL for front-end CMS pages
# If you change this, you will also need to change the PathPart for base()
our $pathpart = 'pages';


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
	return 'main';
}


=head2 default_page

Return the default page.

=cut

sub default_page {
	my ( $self, $c ) = @_;
	
	if ( $c->stash->{ section } ) {
		if ( $c->stash->{ section }->default_page ) {
			return $c->stash->{ section }->default_page->url_name;
		}
		else {
			return $c->stash->{ section }->cms_pages->first->url_name;
		}
	}
	
	# TODO: allow CMS Admins to configure this
	return 'home';
}


=head2 build_menu

Build the menu data structure.

=cut

sub build_menu : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the current date
	$c->stash->{ now } = DateTime->now;
	
	# Build up menu structure
	my $menu_items = [];
	my @sections = $c->model('DB::CmsSection')->search(
		{
			menu_position => { '!=' => undef },
		},
		{
			order_by => 'menu_position',
		},
	);
	foreach my $section ( @sections ) {
		push( @$menu_items, {
			name     => $section->name,
			url_name => $section->url_name,
			link     => '/'. $pathpart .'/'. $section->url_name,
			pages    => [],
		});
		my @pages = $section->cms_pages->search(
			{
				menu_position => { '!=' => undef }
			},
			{
				order_by => 'menu_position'
			},
		);
		foreach my $page ( @pages ) {
			push( @{ $menu_items->[-1]->{ pages } }, {
				name     => $page->name,
				url_name => $page->url_name,
				link     => '/'. $pathpart .'/'. $section->url_name .'/'. $page->url_name,
			} );
		}
	}
	$c->stash->{ menu }{ pages } = $menu_items;
}


=head2 base

Set up path for content pages.

=cut

sub base : Chained( '/' ) : PathPart( 'pages' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the public key for reCaptcha (for use in contact forms)
	$c->stash->{ recaptcha_public_key } = $c->config->{ 'recaptcha_public_key' };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Pages';
}


=head2 admin_base

Set up path for admin pages.

=cut

sub admin_base : Chained( '/' ) : PathPart( 'pages' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 get_section

Fetch the section and stash it.

=cut

sub get_section : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $section ) = @_;
	
	# Get the section
	$c->stash->{ section } = $c->model( 'DB::CmsSection' )->find({
		url_name => $section,
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
	
	$c->stash->{ page } = $section->cms_pages->find({
		url_name => $page,
	});
	
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
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 view_default_page

View the default page for a section if no page is specified.

=cut

sub view_default_page : Chained( 'get_section' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
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
	$c->stash->{ template } = 'pages/cms-templates/'. $c->stash->{ page }->template->filename;
}


=head2 view_page

View a page.

=cut

sub view_page : Chained( 'get_page' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{ template } = 'pages/cms-templates/'. $c->stash->{ page }->template->filename;
}


=head2 preview

Preview a page.

=cut

sub preview : Chained( 'get_page' ) PathPart( 'preview' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to preview CMS pages
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
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
			->find({ id => $c->request->param('template') })->filename;
	}
	else {
		# TODO: get template details from db
		$new_template = $c->stash->{ page }->template->filename;
	}
	
	# Over-ride everything
	$c->stash->{ page     } = $new_details;
	$c->stash->{ elements } = $new_elements;
	$c->stash->{ template } = 'pages/cms-templates/'. $new_template;
	$c->stash->{ preview  } = 'preview';
}


=head2 get_element_types

Return a list of page-element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this
	
	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
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



# ==================== ( Administration ) ====================

# ========== ( Pages ) ==========

=head2 list_pages

View a list of all pages.

=cut

sub list_pages : Chained( 'admin_base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view CMS pages
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'view the list of pages', 
		role   => 'CMS Page Editor',
	});

	my @sections = $c->model( 'DB::CmsSection' )->search(
		{},
		{
			order_by => 'menu_position',
		},
	);
	$c->stash->{ sections } = \@sections;
}


=head2 add_page

Add a new page.

=cut

sub add_page : Chained( 'admin_base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add CMS pages
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new page', 
		role   => 'CMS Page Admin',
	});
	
	# Fetch the list of available sections
	my @sections = $c->model('DB::CmsSection')->search;
	$c->{ stash }->{ sections } = \@sections;
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->{ stash }->{ templates } = \@templates;
	
	# Set the TT template to use
	$c->stash->{template} = 'pages/edit_page.tt';
}


=head2 add_page_do

Process a page addition.

=cut

sub add_page_do : Chained('admin_base') : PathPart('add-page-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add CMS pages
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new page', 
		role   => 'CMS Page Admin',
	});
	
	# Extract page details from form
	my $details = {
		name          => $c->request->param( 'name'          ),
		section       => $c->request->param( 'section'       ) || undef,
		template      => $c->request->param( 'template'      ),
		menu_position => $c->request->param( 'menu_position' ) || undef,
	};
	
	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' );
	$url_name  ||= $c->request->param( 'name'     );
	$url_name   =~ s/\s+/-/g;
	$url_name   =~ s/-+/-/g;
	$url_name   =~ s/[^-\w]//g;
	$url_name   =  lc $url_name;
	$details->{ url_name } = $url_name;
	
	# Check for a collision in the menu_position settings for this section
	my $collision = $c->model( 'DB::CmsPage' )->find({
		section       => $c->request->param( 'section'       ),
		menu_position => $c->request->param( 'menu_position' ),
	});
	
	# Create page
	my $page = $c->model('DB::CmsPage')->create( $details );
	
	# Set up page elements
	my @elements = $c->model('DB::CmsTemplate')->find({
		id => $c->request->param('template'),
	})->cms_template_elements->search;
	
	foreach my $element ( @elements ) {
		my $el = $page->cms_page_elements->create({
			name => $element->name,
			type => $element->type,
		});
	}
	
	# Update the menu_positions for pages in the same section, if necessary
	if ( $collision ) {
		$page->section->cms_pages->search({
			id            => { '!=' => $page->id },
			menu_position => { '>=' => $c->request->param( 'menu_position' ) },
		})->update({
			menu_position => \'menu_position + 1',
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Page added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/'. $pathpart .'/'. $page->section->url_name .'/'. $page->url_name .'/edit' );
}


=head2 edit_page

Edit a page.

=cut

sub edit_page : Chained('get_page') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit CMS pages
	my $page_url = $c->uri_for( '/'. $pathpart, $c->stash->{ page }->section->url_name, $c->stash->{ page }->url_name );
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit a page', 
		role     => 'CMS Page Editor', 
		redirect => $page_url,
	});
	
	$c->{ stash }->{ types  } = get_element_types();
	
	# Stash a list of images present in the images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'images' );
	
	# Fetch the list of available sections
	my @sections = $c->model('DB::CmsSection')->search;
	$c->{ stash }->{ sections } = \@sections;
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->{ stash }->{ templates } = \@templates;
}


=head2 edit_page_do

Process a page update.

=cut

sub edit_page_do : Chained('get_page') : PathPart('edit-page-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit CMS pages
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'edit a page', 
		role   => 'CMS Page Editor',
	});
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param('delete') eq 'Delete' ) {
		die unless $c->user->has_role('CMS Page Admin');	# TODO
		
		$c->stash->{ page }->cms_page_elements->delete;
		$c->stash->{ page }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Page deleted';
		
		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}
	
	# Extract page details from form
	my $details = {
		name          => $c->request->param('name'         ),
		url_name      => $c->request->param('url_name'     ),
		section       => $c->request->param('section'      ) || undef,
		menu_position => $c->request->param('menu_position') || undef,
	};
	
	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' );
	$url_name  ||= $c->request->param( 'name'     );
	$url_name   =~ s/\s+/-/g;
	$url_name   =~ s/-+/-/g;
	$url_name   =~ s/[^-\w]//g;
	$url_name   =  lc $url_name;
	$details->{ url_name } = $url_name;
	
	# Add in the template ID if one was passed in
	$details->{template} = $c->request->param('template') if $c->request->param('template');
	
	# TODO: If template has changed, change element stack
	if ( $c->request->param('template') != $c->stash->{ page }->template->id ) {
		# Fetch old element set
		# Fetch new element set
		# Find the difference between the two sets
		# Add missing elements
		# Remove superfluous elements? Probably not - keep in case of reverts.
	}
	
	# Extract page elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'CMS Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'name'    } = $c->request->param( $input );
		}
		if ( $input =~ m/^type_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'CMS Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'type'    } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
		}
	}
	
	# Check for a collision in the menu_position settings for this section
	my $collision = $c->stash->{ page }->section->cms_pages->find({
		menu_position => $c->request->param( 'menu_position' ),
	});
	
	# Update page
	my $page = $c->stash->{ page }->update( $details );
	
	# Update page elements
	foreach my $element ( keys %$elements ) {
		$c->stash->{ page }->cms_page_elements->find({
				id => $element,
			})->update( $elements->{ $element } );
	}
	
	# Update the menu_positions for pages in the same section, if necessary
	if ( $collision ) {
		$c->stash->{ page }->section->cms_pages->search({
			id            => { '!=' => $c->stash->{ page }->id },
			menu_position => { '>=' => $c->request->param( 'menu_position' ) },
		})->update({
			menu_position => \'menu_position + 1',
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';
	
	# Bounce back to the 'edit' page
	my $path = '/'. $pathpart;
	$path   .= '/'. $page->section->url_name if $page->section;
	$path   .= '/'. $page->url_name .'/edit';
	$c->response->redirect( $path );
}


=head2 add_element_do

Add an element to a page.

=cut

sub add_element_do : Chained( 'get_page' ) : PathPart( 'add_element_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to change CMS templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add an element to a page', 
		role   => 'CMS Page Editor',
	});
	
	# Extract page element from form
	my $element = $c->request->param('new_element');
	my $type    = $c->request->param('new_type'   );
	
	# Update the database
	$c->model('DB::CmsPageElement')->create({
		page => $c->stash->{ page }->id,
		name => $element,
		type => $type,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';
	
	# Bounce back to the 'edit' page
	my $path = '/'. $pathpart;
	$path   .= '/'. $c->stash->{ page }->section->url_name if $c->stash->{ page }->section;
	$path   .= '/'. $c->stash->{ page }->url_name .'/edit';
	$c->response->redirect( $path );
}


# ========== ( Sections ) ==========

=head2 list_sections

List all the CMS sections.

=cut

sub list_sections : Chained( 'admin_base' ) : PathPart( 'list-sections' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view CMS sections
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'view the list of sections', 
		role   => 'CMS Page Admin',
	});

	my @sections = $c->model( 'DB::CmsSection' )->all;
	$c->stash->{ sections } = \@sections;
}


=head2 stash_section

Stash details relating to a CMS section.

=cut

sub stash_section : Chained( 'admin_base' ) : PathPart( 'section' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $section_id ) = @_;
	
	$c->stash->{ section } = $c->model( 'DB::CmsSection' )->find( { id => $section_id } );
	
	unless ( $c->stash->{ section } ) {
		$c->flash->{ error_msg } = 
			'Specified section not found - please select from the options below';
		$c->go( 'list_sections' );
	}
}


=head2 add_section

Add a CMS section.

=cut

sub add_section : Chained( 'admin_base' ) : PathPart( 'add-section' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add sections
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new section', 
		role   => 'CMS Page Admin',
	});
	
	$c->stash->{ template } = 'pages/edit_section.tt';
}


=head2 add_section_do

Process adding a section.

=cut

sub add_section_do : Chained( 'admin_base' ) : PathPart( 'add-section-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add sections
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new section', 
		role   => 'CMS Page Admin',
	});
	
	# Create section
	my $section = $c->model( 'DB::CmsSection' )->create({
		name          => $c->request->param( 'name'          ) || undef,
		url_name      => $c->request->param( 'url_name'      ) || undef,
		menu_position => $c->request->param( 'menu_position' ) || undef,
		description   => $c->request->param( 'description'   ) || undef,
		default_page  => $c->request->param( 'default_page'  ) || undef,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'New section created';
	
	# Bounce back to the list of sections
	$c->response->redirect( $c->uri_for( 'list-sections' ) );
}


=head2 edit_section

Edit a CMS section.

=cut

sub edit_section : Chained( 'stash_section' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in and a page admin
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'edit a section', 
		role   => 'CMS Page Admin',
	});
}


=head2 edit_section_do

Process a CMS section edit.

=cut

sub edit_section_do : Chained( 'stash_section' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit CMS sections
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'edit a section', 
		role   => 'CMS Page Admin',
	});
	
	# Process deletions
	if ( $c->request->param( 'delete' ) eq 'Delete' ) {
		# Delete pages in section
		my @pages = $c->stash->{ section }->cms_pages;
		foreach my $page ( @pages ) {
			$page->cms_page_elements->delete;
		}
		$c->stash->{ section }->cms_pages->delete;
		# Delete section
		$c->stash->{ section }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Section deleted';
		
		# Bounce to the 'view all sections' page
		$c->response->redirect( $c->uri_for( 'list-sections' ) );
		return;
	}
	
	# Update section
	$c->stash->{ section }->update({
		name          => $c->request->param( 'name'          ) || undef,
		url_name      => $c->request->param( 'url_name'      ) || undef,
		menu_position => $c->request->param( 'menu_position' ) || undef,
		description   => $c->request->param( 'description'   ) || undef,
		default_page  => $c->request->param( 'default_page'  ) || undef,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Section details updated';
	
	# Bounce back to the list of sections
	$c->response->redirect( $c->uri_for( 'section', $c->stash->{ section }->id, 'edit' ) );
}


# ========== ( Templates ) ==========

=head2 list_templates

List all the CMS templates.

=cut

sub list_templates : Chained('admin_base') : PathPart('list-templates') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view CMS page templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'view the list of page templates', 
		role   => 'CMS Template Admin',
	});

	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->stash->{ cms_templates } = \@templates;
}


=head2 get_template

Stash details relating to a CMS template.

=cut

sub get_template : Chained('admin_base') : PathPart('template') : CaptureArgs(1) {
	my ( $self, $c, $template_id ) = @_;
	
	$c->stash->{ cms_template } = $c->model('DB::CmsTemplate')->find( { id => $template_id } );
	
	unless ( $c->stash->{ cms_template } ) {
		$c->flash->{ error_msg } = 
			'Specified template not found - please select from the options below';
		$c->go('list_templates');
	}
	
	# Get template elements
	my @elements = $c->model('DB::CmsTemplateElement')->search( {
		template => $c->stash->{ cms_template }->id,
	} );
	
	$c->stash->{ template_elements } = \@elements;
}


=head2 get_template_filenames

Get a list of available template filenames.

=cut

sub get_template_filenames {
	my ( $c ) = @_;
	
	my $template_dir = $c->path_to('root/pages/cms-templates');
	opendir( my $template_dh, $template_dir ) 
		or die "Failed to open template directory $template_dir: $!";
	my @templates;
	foreach my $filename ( readdir( $template_dh ) ) {
		next if $filename =~ m/^\./; # skip hidden files
		next if $filename =~ m/~$/;  # skip backup files
		push @templates, $filename;
	}
	
	return \@templates;
}


=head2 add_template

Add a CMS template.

=cut

sub add_template : Chained( 'admin_base' ) : PathPart( 'add-template' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new template', 
		role   => 'CMS Template Admin',
	});
	
	$c->{ stash }->{ template_filenames } = get_template_filenames( $c );
	
	$c->{ stash }->{ types  } = get_element_types();
	
	$c->stash->{ template } = 'pages/edit_template.tt';
}


=head2 add_template_do

Process a template addition.

=cut

sub add_template_do : Chained( 'admin_base' ) : PathPart( 'add-template-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new template', 
		role   => 'CMS Template Admin',
	});
	
	# Create template
	my $template = $c->model( 'DB::CmsTemplate' )->create({
		name     => $c->request->param( 'name'     ),
		filename => $c->request->param( 'filename' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Template details saved';
	
	# Bounce back to the template list
	$c->response->redirect( $c->uri_for( 'list-templates' ) );
}


=head2 edit_template

Edit a CMS template.

=cut

sub edit_template : Chained('get_template') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in and a template admin
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'edit a template', 
		role   => 'CMS Template Admin',
	});
	
	$c->{ stash }->{ types  } = get_element_types();
	
	$c->{ stash }->{ template_filenames } = get_template_filenames( $c );
}


=head2 edit_template_do

Process a CMS template edit.

=cut

sub edit_template_do : Chained( 'get_template' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit CMS templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'edit a template', 
		role   => 'CMS Template Admin',
	});
	
	# Process deletions
	if ( $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ cms_template }->cms_template_elements->delete;
		$c->stash->{ cms_template }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Template deleted';
		
		# Bounce to the 'view all templates' page
		$c->response->redirect( $c->uri_for( 'list-templates' ) );
		return;
	}
	
	# Update template
	my $template = $c->model('DB::CmsTemplate')->find({
					id => $c->stash->{ cms_template }->id
				})->update({
					name     => $c->request->param('name'    ),
					filename => $c->request->param('filename'),
				});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Template details updated';
	
	# Bounce back to the list of templates
	$c->response->redirect( $c->uri_for( 'list-templates' ) );
}


=head2 add_template_element_do

Add an element to a template.

=cut

sub add_template_element_do : Chained( 'get_template' ) : PathPart( 'add_template_element_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add template elements
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'add a new element to a template', 
		role   => 'CMS Template Admin',
	});
	
	# Extract element from form
	my $element = $c->request->param( 'new_element' );
	my $type    = $c->request->param( 'new_type'    );
	
	# Update the database
	$c->model( 'DB::CmsTemplateElement' )->create({
		template => $c->stash->{ cms_template }->id,
		name     => $element,
		type     => $type,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'template', $c->stash->{ cms_template }->id, 'edit' ) );
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

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

