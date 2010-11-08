package ShinyCMS::Controller::Newsletters;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Newsletters

=head1 DESCRIPTION

Controller for ShinyCMS newsletter features.

=head1 METHODS

=cut


=head2 index

Display a list of recent newsletters.

=cut

sub index : Path : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'view_recent' );
}


=head2 base

Set up path and stash some useful stuff.

=cut

sub base : Chained( '/' ) : PathPart( 'newsletters' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Newsletters';
}


=head2 get_newsletter

Get the details for a newsletter.

=cut

sub get_newsletter : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	# Get the newsletter
	$c->stash->{ newsletter } = $c->model( 'DB::Newsletter' )->search({
		url_title => $url_title,
		-nest => \[ 'year(sent)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(sent) = ?', [ plain_value => $month ] ],
	})->first;
	
	# Get page elements
	my @elements = $c->model( 'DB::NewsletterElement' )->search({
		newsletter => $c->stash->{ newsletter }->id,
	});
	$c->stash->{ newsletter_elements } = \@elements;
	
	# Build up 'elements' structure for use in cms-templates
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
}


=head2 get_newsletters

Get a page's worth of newsletters

=cut

sub get_newsletters {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $now = DateTime->now;
	
	my @newsletters = $c->model( 'DB::Newsletter' )->search(
		{
			sent     => { '<=' => $now },
		},
		{
			order_by => { -desc => 'sent' },
			page     => $page,
			rows     => $count,
		},
	);

	return \@newsletters;
}


=head2 view_newsletter

View a newsletter.

=cut

sub view_newsletter : Chained( 'get_newsletter' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{ template } = 'newsletters/newsletter-templates/'. $c->stash->{ newsletter }->template->filename;
}


=head2 view_newsletters

Display a page of newsletters.

=cut

sub view_newsletters : Chained( 'base' ) : PathPart( 'view' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $newsletters = $self->get_newsletters( $c, $page, $count );
	
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ newsletters } = $newsletters;
}


=head2 view_recent

Display recent blog posts.

=cut

sub view_recent : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'view_newsletters', [ 1, 10 ] );
}


=head2 preview

Preview a newsletter.

=cut

sub preview : Chained( 'get_newsletter' ) PathPart( 'preview' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to preview newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'preview page edits', 
		role   => 'Newsletter Admin',
	});
	
	# Extract newsletter details from form
	my $new_details = {
		title     => $c->request->param( 'title'     ) || 'No title given',
		url_title => $c->request->param( 'url_title' ) || 'No url_title given',
	};
	
	# Extract newsletter elements from form
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
	# And set them up for insertion into the preview
	my $new_elements = {};
	foreach my $key ( keys %$elements ) {
		$new_elements->{ $elements->{ $key }->{ name } } = $elements->{ $key }->{ content };
	}
	
	# Set the TT template to use
	my $new_template;
	if ( $c->request->param( 'template' ) ) {
		$new_template = $c->model( 'DB::NewsletterTemplate' )
			->find({ id => $c->request->param( 'template' ) })->filename;
	}
	else {
		# TODO: get template details from db
		$new_template = $c->stash->{ newsletter }->template->filename;
	}
	
	# Over-ride everything
	$c->stash->{ newsletter } = $new_details;
	$c->stash->{ elements   } = $new_elements;
	$c->stash->{ template   } = 'newsletters/newsletter-templates/'. $new_template;
	$c->stash->{ preview    } = 'preview';
}



=head1 AUTHOR

Denny de la Haye <2010@denny.me>

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

