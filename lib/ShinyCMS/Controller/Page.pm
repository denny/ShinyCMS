package Reactant::Controller::Page;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

Reactant::Controller::Page

=head1 DESCRIPTION

Main controller for Reactant's CMS pages.

=head1 METHODS

=cut


=head2 index

Forward to the default page if no page is specified.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: $c->go( default_page() );
	$c->go( 'view' );
}


=head2 get_page

Fetch the page and stash it.

=cut

sub get_page : Chained('/') : PathPart('page') : CaptureArgs(1) {
	my ( $self, $c, $url_name ) = @_;
	
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


=head2 view

View a page.

=cut

sub view : Chained('get_page') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{template} = 'cms_templates/'. $c->stash->{ page }->template->filename;
}


=head2 edit

Edit a page.

=cut

sub edit : Chained('get_page') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::CmsTemplate')->search({});
	$c->{ stash }->{ templates } = \@templates;
}


=head2 edit_do

Process a page update.

=cut

sub edit_do : Chained('get_page') : PathPart('edit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: Check to see if user is allowed to edit pages/templates
	# ...
	
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
			#TODO: skip unless user is a template admin
			#next unless $user->has_role('template_admin');
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
	$c->response->redirect( '/page/'. $c->request->params->{ url_name } .'/edit' );
}



=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

