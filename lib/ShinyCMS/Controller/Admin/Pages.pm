package ShinyCMS::Controller::Admin::Pages;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

use ShinyCMS::Duplicator;


BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Pages

=head1 DESCRIPTION

Controller for ShinyCMS page admin features.

=cut


has page_prefix => (
	isa     => Str,
	is      => 'ro',
	default => 'pages',
);

has hide_new_pages => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has hide_new_sections => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);


=head1 METHODS

=head2 base

Set up path for admin pages.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/pages' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to view and edit CMS pages
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'view and edit CMS pages',
		role     => 'CMS Page Editor',
		redirect => '/admin'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Pages';

	# Stash the page prefix, in case we need it to construct URLs
	$c->stash->{ page_prefix } = $self->page_prefix;
}


=head2 index

Bounce to list of pages.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_pages' );
}


=head2 get_element_types

Return a list of page-element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this

	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
}


# ========== ( Pages ) ==========

=head2 list_pages

View a list of all pages.

=cut

sub list_pages : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @sections = $c->model( 'DB::CmsSection' )->search(
		{},
		{
			order_by => 'menu_position',
		},
	);
	$c->stash->{ sections } = \@sections;

	$c->stash->{ clone_destination } = $self->clone_destination_name( $c );
}


=head2 get_page

Fetch the page elements and stash them.

=cut

sub get_page : Chained( 'base' ) : PathPart( 'page' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $page_id ) = @_;

	# Get page elements
	my $page = $c->model( 'DB::CmsPage' )->find({
		id => $page_id,
	});
	$c->stash->{ page    } = $page;
	$c->stash->{ section } = $page->section;

	my @elements = $c->model( 'DB::CmsPageElement' )->search({
		page => $page_id,
	});
	$c->stash->{ page_elements } = \@elements;

	# Build up 'elements' structure for use in cms-templates
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
}


=head2 add_page

Add a new page.

=cut

sub add_page : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to add CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new page',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	# Fetch the list of available sections
	my @sections = $c->model( 'DB::CmsSection' )->search(
		{},
		{
			order_by => 'name',
		}
	)->all;
	$c->stash->{ sections } = \@sections;

	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search(
		{},
		{
			order_by => 'name',
		}
	)->all;
	$c->stash->{ templates } = \@templates;

	# Stash 'hide new pages' setting
	$c->stash->{ hide_new_pages } = 1 if uc $self->hide_new_pages eq 'YES';

	# Set the TT template to use
	$c->stash->{template} = 'admin/pages/edit_page.tt';
}


=head2 add_page_do

Process a page addition.

=cut

sub add_page_do : Chained( 'base' ) : PathPart( 'add-page-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to add CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new page',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	# Extract page details from form
	my $details = {
		name          => $c->request->param( 'name'        ),
		description   => $c->request->param( 'description' ),
		section       => $c->request->param( 'section'     ),
		template      => $c->request->param( 'template'    ),
		hidden        => $c->request->param( 'hidden'      ) ? 1 : 0,
		menu_position => $self->safe_param( $c, 'menu_position' ),
	};

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $self->safe_param( $c, 'name' );
	$url_name = $self->make_url_slug( $url_name );
	$details->{ url_name } = $url_name;

	# Make sure the page title is set
	my $title = $c->request->param( 'title' );
	$title  ||= $c->request->param( 'name'  );
	$details->{ title } = $title;

	# Check for a collision in the menu_position settings for this section
	my $collision = $c->model( 'DB::CmsPage' )->search({
		section       => $c->request->param( 'section'       ),
		menu_position => $c->request->param( 'menu_position' ),
	})->count;

	# Create page
	my $page = $c->model( 'DB::CmsPage' )->create( $details );

	# Set up page elements
	my @elements = $c->model( 'DB::CmsTemplate' )->find({
		id => $c->request->param( 'template' ),
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
	$c->response->redirect( $c->uri_for( 'page', $page->id, 'edit' ) );
}


=head2 edit_page

Edit a page.

=cut

sub edit_page : Chained( 'get_page') : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of element types
	$c->stash->{ types  } = get_element_types();

	# Fetch the list of available sections
	my @sections = $c->model( 'DB::CmsSection' )->search(
		{},
		{
			order_by => 'name',
		}
	)->all;
	$c->stash->{ sections } = \@sections;

	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search(
		{},
		{
			order_by => 'name',
		}
	)->all;
	$c->stash->{ templates } = \@templates;

	# Stash a list of images present in the images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c );
}


=head2 edit_page_do

Process a page update.

=cut

sub edit_page_do : Chained( 'get_page' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		my $page = $c->stash->{ page };
		my $page_url = $c->uri_for( '/admin/pages/page', $page->id, 'edit' );

		return 0 unless $self->user_exists_and_can( $c, {
			action   => 'delete a page',
			role     => 'CMS Page Admin',
			redirect => $page_url,
		});

		# Check to see if this page is the default for its section
		if ( $page->section->default_page and
			 $page->section->default_page->id == $page->id ) {
			# Remove the default setting for the section
			$page->section->update({ default_page => undef });
		}

		# Delete elements, delete page
		$page->cms_page_elements->delete;
		$page->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Page deleted';

		# Bounce to the default page
		$c->response->redirect( $c->uri_for( '/admin/pages/list' ) );
		$c->detach;
	}

	# Extract page details from form
	my $details = {
		name          => $c->request->param( 'name'          ),
		section       => $c->request->param( 'section'       ),
		description   => $c->request->param( 'description'   ),
		menu_position => $self->safe_param( $c, 'menu_position' ),
		hidden        => $c->request->param( 'hidden'        ) ? 1 : 0,
	};

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $self->safe_param( $c, 'name' );
	$url_name = $self->make_url_slug( $url_name );
	$details->{ url_name } = $url_name;

	# Make sure the page title is set
	my $title = $c->request->param( 'title' );
	$title  ||= $c->request->param( 'name'  );
	$details->{ title } = $title;

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
	my $user_is_template_admin = $c->user->has_role( 'CMS Template Admin' );
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
			if ( length $elements->{ $id }{ 'content' } > 65000 ) {
				$elements->{ $id }{ 'content' } = substr $elements->{ $id }{ 'content' }, 0, 65500;
				$c->flash->{ error_msg } = 'Long field truncated (over 65,500 characters!)';
			}
		}
		next unless $user_is_template_admin;
		if ( $input =~ m/^name_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'name' } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^type_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'type' } = $c->request->param( $input );
		}
	}

	# Check for a collision in the menu_position settings for this section
	my $collision = $c->stash->{ page }->section->cms_pages->search({
		id            => { '!=' => $c->stash->{ page }->id },
		section       => $c->stash->{ section }->id,
		menu_position => $c->request->param( 'menu_position' ),
	})->count;

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
	$c->response->redirect( $c->uri_for( 'page', $page->id, 'edit' ) );
}


=head2 add_element_do

Add an element to a page.

=cut

sub add_element_do : Chained( 'get_page' ) : PathPart( 'add_element_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to change CMS templates
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add an element to a page',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
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
	$c->response->redirect(
		$c->uri_for( 'page', $c->stash->{ page }->id, 'edit' ) .'#add_element'
	);
}


=head2 clone_page

Clone a page using the Duplicator

=cut

sub clone_page : Chained( 'get_page' ) : PathPart( 'clone' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'clone a page',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	my $destination_db = $self->clone_destination_schema( $c );

	if ( $destination_db ) {
		my $duplicator = ShinyCMS::Duplicator->new({
			source_db      => $c->model( 'DB' )->schema,
			destination_db => $destination_db,
			source_item    => $c->stash->{ page },
		});
		$duplicator->clone;

		if ( $duplicator->has_errors ) {
			$c->flash->{ error_msg } = 'Cloning failed';
		}
		else {
			my $hide = $c->config->{ DuplicatorDestination }->{ hide_clones } || 0;
			$duplicator->cloned_item->update_all({ hidden => 1 }) if $hide;

			$c->flash->{ status_msg } = $duplicator->result;
		}
	}
	else {
		$c->flash->{ error_msg } = 'Failed to connect to cloning destination';
	}

	$c->response->redirect( $c->uri_for( '/admin/pages/list' ) );
}



# ========== ( Sections ) ==========

=head2 list_sections

List all the CMS sections.

=cut

sub list_sections : Chained( 'base' ) : PathPart( 'sections' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to view CMS sections
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view the list of sections',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	my @sections = $c->model( 'DB::CmsSection' )->all;
	$c->stash->{ sections } = \@sections;
}


=head2 stash_section

Stash details relating to a CMS section.

=cut

sub stash_section : Chained( 'base' ) : PathPart( 'section' ) : CaptureArgs( 1 ) {
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

sub add_section : Chained( 'base' ) : PathPart( 'section/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to add sections
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new section',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	# Stash 'hide new sections' setting
	$c->stash->{ hide_new_sections } = 1 if uc $self->hide_new_sections eq 'YES';

	$c->stash->{ template } = 'admin/pages/edit_section.tt';
}


=head2 add_section_do

Process adding a section.

=cut

sub add_section_do : Chained( 'base' ) : PathPart( 'section/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to add sections
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new section',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $self->safe_param( $c, 'name' );
	$url_name = $self->make_url_slug( $url_name );

	# Create section
	my $section = $c->model( 'DB::CmsSection' )->create({
		name          => $c->request->param( 'name'          ),
		url_name      => $url_name,
		description   => $c->request->param( 'description'   ),
		default_page  => $self->safe_param( $c, 'default_page'  ),
		menu_position => $self->safe_param( $c, 'menu_position' ),
		hidden        => $c->request->param( 'hidden'        ) ? 1 : 0,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'New section created';

	# Bounce to the new section's edit page
	my $url = $c->uri_for( '/admin/pages/section', $section->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_section

Edit a CMS section.

=cut

sub edit_section : Chained( 'stash_section' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Bounce if user isn't logged in and a page admin
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a section',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});
}


=head2 edit_section_do

Process a CMS section edit.

=cut

sub edit_section_do : Chained( 'stash_section' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to edit CMS sections
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a section',
		role     => 'CMS Page Admin',
		redirect => '/admin/pages'
	});

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
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
		$c->response->redirect( $c->uri_for( '/admin/pages/sections' ) );
		$c->detach;
	}

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $self->safe_param( $c, 'name' );
	$url_name = $self->make_url_slug( $url_name );

	# Update section
	$c->stash->{ section }->update({
		name          => $c->request->param( 'name'          ),
		url_name      => $url_name,
		description   => $c->request->param( 'description'   ),
		default_page  => $self->safe_param( $c, 'default_page'  ),
		menu_position => $self->safe_param( $c, 'menu_position' ),
		hidden        => $c->request->param( 'hidden'        ) ? 1 : 0,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Section details updated';

	# Bounce to the edit page
	my $url = $c->uri_for( '/admin/pages/section', $c->stash->{ section }->id, 'edit' );
	$c->response->redirect( $url );
}


# ========== ( Templates ) ==========

=head2 list_templates

List all the CMS templates.

=cut

sub list_templates : Chained('base') : PathPart('templates') : Args(0) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to view CMS page templates
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view the list of page templates',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	my @templates = $c->model('DB::CmsTemplate')->search(
		{},
		{
			order_by => 'name',
		}
	)->all;

	$c->stash->{ cms_templates } = \@templates;

	$c->stash->{ clone_destination } = $self->clone_destination_name( $c );
}


=head2 get_template

Stash details relating to a CMS template.

=cut

sub get_template : Chained('base') : PathPart('template') : CaptureArgs(1) {
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

	my $template_dir = $c->path_to( 'root/pages/cms-templates' );
	opendir( my $template_dh, $template_dir )
		or die "Failed to open template directory $template_dir: $!";
	my @templates;
	foreach my $filename ( readdir( $template_dh ) ) {
		next if $filename =~ m/^\./; # skip hidden files
		next if $filename =~ m/~$/;  # skip backup files
		push @templates, $filename;
	}
	@templates = sort @templates;

	return \@templates;
}


=head2 add_template

Add a CMS template.

=cut

sub add_template : Chained( 'base' ) : PathPart( 'template/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to add templates
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	$c->stash->{ template_filenames } = get_template_filenames( $c );

	$c->stash->{ types  } = get_element_types();

	$c->stash->{ template } = 'admin/pages/edit_template.tt';
}


=head2 add_template_do

Process a template addition.

=cut

sub add_template_do : Chained( 'base' ) : PathPart( 'template/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to add templates
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	# Create template
	my $template = $c->model( 'DB::CmsTemplate' )->create({
		name          => $c->request->param( 'name'     ),
		template_file => $c->request->param( 'template_file' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Template details saved';

	# Bounce back to the template's edit page
	my $url = $c->uri_for( '/admin/pages/template', $template->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_template

Edit a CMS template.

=cut

sub edit_template : Chained( 'get_template' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Bounce if user isn't logged in and a template admin
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	$c->stash->{ types  } = get_element_types();

	$c->stash->{ template_filenames } = get_template_filenames( $c );
}


=head2 edit_template_do

Process a CMS template edit.

=cut

sub edit_template_do : Chained( 'get_template' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to edit CMS templates
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->stash->{ cms_template }->cms_template_elements->delete;
		$c->stash->{ cms_template }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Template deleted';

		# Bounce to the 'view all templates' page
		$c->response->redirect( $c->uri_for( '/admin/pages/templates' ) );
		return;
	}

	# Update template
	my $template = $c->model('DB::CmsTemplate')->find({
					id => $c->stash->{ cms_template }->id
				})->update({
					name          => $c->request->param('name'    ),
					template_file => $c->request->param('template_file'),
				});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Template details updated';

	# Bounce back to the template's edit page
	my $url = $c->uri_for( '/admin/pages/template', $template->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 add_template_element_do

Add an element to a template.

=cut

sub add_template_element_do : Chained( 'get_template' ) : PathPart( 'add_template_element_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to add template elements
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add a new element to a template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
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
	# Bounce back to the 'edit' page
	$c->response->redirect(
		$c->uri_for( 'template', $c->stash->{ cms_template }->id, 'edit' ) 	.'#add_element'
	);
}


=head2 delete_template_element

Remove an element from a template.

=cut

sub delete_template_element : Chained( 'get_template' ) : PathPart( 'delete-element' ) : Args( 1 ) {
	my ( $self, $c, $element_id ) = @_;

	# Check to see if user is allowed to add template elements
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'delete an element from a template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	# Update the database
	$c->model( 'DB::CmsTemplateElement' )->find({
		id => $element_id,
	})->delete;

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element removed';

	# Bounce back to the 'edit' page
	$c->response->redirect(
		$c->uri_for( 'template', $c->stash->{ cms_template }->id, 'edit' )
	);
}


=head2 clone_template

Clone a page template using the Duplicator

=cut

sub clone_template : Chained( 'get_template' ) : PathPart( 'clone' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'clone a template',
		role     => 'CMS Template Admin',
		redirect => '/admin/pages'
	});

	my $destination_db = $self->clone_destination_schema( $c );

	if ( $destination_db ) {
		my $duplicator = ShinyCMS::Duplicator->new({
			source_db      => $c->model( 'DB' )->schema,
			destination_db => $destination_db,
			source_item    => $c->stash->{ cms_template },
		});
		$duplicator->clone;

		if ( $duplicator->has_errors ) {
			$c->flash->{ error_msg } = 'Cloning failed';
		}
		else {
			$c->flash->{ status_msg } = $duplicator->result;
		}
	}
	else {
		$c->flash->{ error_msg } = 'Failed to connect to cloning destination';
	}

	$c->response->redirect( $c->uri_for( 'templates' ) );
}


=head2 clone_destination_name

Return the name of the configured cloning destination, if one exists

=cut

sub clone_destination_name : Private {
	my ( $self, $c ) = @_;

	return unless $c->config->{ DuplicatorDestination };

	return $c->config->{ DuplicatorDestination }->{ name } ||
				 $c->config->{ DuplicatorDestination }->{ connect_info }->{ dsn };
}


=head2 clone_destination_schema

Return the configured cloning destination schema (if any)

=cut

sub clone_destination_schema : Private {
	my ( $self, $c ) = @_;

	return unless $c->config->{ DuplicatorDestination };

	return ShinyCMS::Schema->connect(
		$c->config->{ DuplicatorDestination }->{ connect_info }
	);
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
