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
	unless ( $c->user ) {
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
	my $page = $c->model('DB::CmsPage')->find({
					id => $c->stash->{ page }->id,
				})->update( $details );
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Page added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/page/'. $c->request->params->{ url_name } .'/edit' );
}


=head2 edit_page

Edit a page.

=cut

sub edit_page : Chained('get_page') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user ) {
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


=head2 edit_do

Process a page update.

=cut

sub edit_do : Chained('get_page') : PathPart('edit_page_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit CMS pages
	die unless $c->user->has_role('CMS Page Editor');
	
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
	# TODO: something more graceful than die()
	die unless $c->user->has_role('CMS Template Admin');
	
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



=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

