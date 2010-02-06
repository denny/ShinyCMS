package ShinyCMS::Controller::Page;

use strict;
use warnings;

use parent 'Catalyst::Controller';


=head1 NAME

ShinyCMS::Controller::Page

=head1 DESCRIPTION

Main controller for ShinyCMS's CMS pages.

=head1 METHODS

=cut


=head2 index

Forward to the default page if no page is specified.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->response->redirect( $c->uri_for('/page/'. default_page() ) );
}


=head2 default_page

Return the default page.

=cut

sub default_page {
	# TODO: allow CMS Admins to set a default page which can be retrieved with this method
	return 'home';
}


=head2 base

Set up path.

=cut

sub base : Chained('/') : PathPart('page') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
}


=head2 list_all

View a list of all pages.

=cut

sub list_all : Chained('base') : PathPart('list-all') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @pages = $c->model('DB::CmsPage')->search;
	$c->stash->{ pages } = \@pages;
}


=head2 get_page

Fetch the page and stash it.

=cut

sub get_page : Chained('base') : PathPart('') : CaptureArgs(1) {
	my ( $self, $c, $url_name ) = @_;
	
	# get the default page if none is specified
	$url_name ||= default_page();
	
	$c->stash->{ page } = $c->model('DB::CmsPage')->find( { url_name => $url_name } );
	
	# TODO: 404 handler
	die "Page $url_name not found" unless $c->stash->{ page };
	
	my @elements = $c->model('DB::CmsPageElement')->search( {
		page => $c->stash->{ page }->id,
	} );
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
	$c->stash->{ page_elements } = \@elements;
}


=head2 view_page

View a page.

=cut

sub view_page : Chained('get_page') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{template} = 'cms_templates/'. $c->stash->{ page }->template->filename;
}


=head2 add_page

Add a new page.

=cut

sub add_page : Chained('base') : PathPart('add') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to add CMS pages.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a CMS page admin
	unless ( $c->user->has_role('CMS Page Admin') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to add CMS pages.';
		$c->response->redirect( $c->uri_for( '/page' ) );
	}
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->{ stash }->{ templates } = \@templates;
	
	# Set the TT template to use
	$c->stash->{template} = 'page/edit_page.tt';
}


=head2 add_page_do

Process a page addition.

=cut

sub add_page_do : Chained('base') : PathPart('add_page_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add CMS pages
	die unless $c->user->has_role('CMS Page Admin');
	
	# Extract page details from form
	my $details = {
		name		=> $c->request->params->{ name	   },
		url_name	=> $c->request->params->{ url_name },
		template	=> $c->request->params->{ template },
	};
	
	# Create page
	my $page = $c->model('DB::CmsPage')->create( $details );
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Page added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/page/'. $page->url_name .'/edit' );
}


=head2 edit_page

Edit a page.

=cut

sub edit_page : Chained('get_page') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit CMS pages.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a CMS page editor
	unless ( $c->user->has_role('CMS Page Editor') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit CMS pages.';
		$c->response->redirect( $c->uri_for( '/page/'. $c->stash->{ page }->url_name ) );
	}
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->{ stash }->{ templates } = \@templates;
}


=head2 edit_page_do

Process a page update.

=cut

sub edit_page_do : Chained('get_page') : PathPart('edit_page_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit CMS pages
	die unless $c->user->has_role('CMS Page Editor');	# TODO
	
	# Process deletions
	if ( $c->request->params->{ delete } eq 'Delete' ) {
		die unless $c->user->has_role('CMS Page Admin');	# TODO
		
		$c->model('DB::CmsPageElement')->find({
				page => $c->stash->{ page }->id
			})->delete;
		$c->model('DB::CmsPage')->find({
				id => $c->stash->{ page }->id
			})->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Page deleted';
		
		# Bounce to the default page
		$c->response->redirect( '/page' );
		return;
	}
	
	# Extract page details from form
	my $details = {
		name		=> $c->request->params->{ name	   },
		url_name	=> $c->request->params->{ url_name },
		template	=> $c->request->params->{ template },
	};
	
	# Extract page elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role('CMS Template Admin');
			my $id = $1;
			$elements->{ $id } = { name => $c->request->params->{ $input } };
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id } = { content => $c->request->params->{ $input } };
		}
	}
	
	# Update page
	my $page = $c->model('DB::CmsPage')->find({
					id => $c->stash->{ page }->id,
				})->update( $details );
	
	# Update page elements
	foreach my $element ( keys %{$elements} ) {
		$c->model('DB::CmsPageElement')->find({
					id => $element,
				})->update( $elements->{$element} );
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/page/'. $page->url_name .'/edit' );
}


=head2 add_element_do

Add an element to a page.

=cut

sub add_element_do : Chained('get_page') : PathPart('add_element_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to change CMS templates
	die unless $c->user->has_role('CMS Template Admin');	# TODO
	
	# Extract page element from form
	my $element = $c->request->params->{ new_element };
	
	# Update the database
	$c->model('DB::CmsPageElement')->create({
		page => $c->stash->{ page }->id,
		name => $element,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Element added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/page/'. $c->stash->{ page }->url_name .'/edit' );
}


=head2 list_templates

List all the CMS templates.

=cut

sub list_templates : Chained('base') : PathPart('templates') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @templates = $c->model('DB::CmsTemplate')->search;
	$c->stash->{ cms_templates } = \@templates;
}


=head2 get_template

Stash details relating to a CMS template.

=cut

sub get_template : Chained('base') : PathPart('template') : CaptureArgs(1) {
	my ( $self, $c, $template_id ) = @_;
	
	$c->stash->{ cms_template } = $c->model('DB::CmsTemplate')->find( { id => $template_id } );
	
	# TODO: better 404 handler here?
	unless ( $c->stash->{ cms_template } ) {
		$c->flash->{ error_msg } = 
			'Specified template not found - please select from the options below';
		$c->go('list_templates');
	}
}


=head2 add_template

Add a CMS template.

=cut

sub add_template : Chained('base') : PathPart('add-template') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Block if user isn't logged in
	unless ( $c->user_exists ) {
		$c->flash->{ error_msg } = 'You must be logged in to edit CMS templates.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a shop admin
	unless ( $c->user->has_role('CMS Template Admin') ) {
		$c->flash->{ error_msg } = 'You do not have the ability to edit CMS templates.';
		$c->response->redirect( $c->uri_for( '/page' ) );
	}
	
	$c->stash->{template} = 'page/edit_template.tt';
}


=head2 add_template_do

Process a template addition.

=cut

sub add_template_do : Chained('base') : PathPart('add-template-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add templates
	die unless $c->user->has_role('CMS Template Admin');	# TODO
	
	# Create category
	my $template = $c->model('DB::CmsTemplate')->create({
		name     => $c->request->params->{ name	    },
		filename => $c->request->params->{ filename	},
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Template details saved';
	
	# Bounce back to the template list
	$c->response->redirect( '/page/templates' );
}


=head2 edit_template

Edit a CMS template.

=cut

sub edit_template : Chained('get_template') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Block if user isn't logged in
	unless ( $c->user_exists ) {
		$c->flash->{ error_msg } = 'You must be logged in to edit CMS templates.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a template admin
	unless ( $c->user->has_role('CMS Template Admin') ) {
		$c->flash->{ error_msg } = 'You do not have the ability to edit CMS templates.';
		$c->response->redirect( $c->uri_for( '/page' ) );
	}
}


=head2 edit_template_do

Process a CMS template edit.

=cut

sub edit_template_do : Chained('get_template') : PathPart('edit-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit CMS templates
	die unless $c->user->has_role('CMS Template Admin');	# TODO
	
	# Process deletions
	if ( $c->request->params->{ 'delete' } eq 'Delete' ) {
		$c->model('DB::CmsTemplate')->find({
				id => $c->stash->{ cms_template }->id
			})->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Template deleted';
		
		# Bounce to the 'view all templates' page
		$c->response->redirect( '/page/templates' );
		return;
	}
	
	# Update template
	my $template = $c->model('DB::CmsTemplate')->find({
					id => $c->stash->{ cms_template }->id
				})->update({
					name     => $c->request->params->{ name	   },
					filename => $c->request->params->{ filename },
				});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Template details updated';
	
	# Bounce back to the category list
	$c->response->redirect( '/page/templates' );
}



=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

1;

