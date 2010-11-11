package ShinyCMS::Controller::Admin::Newsletters;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


#use Text::CSV::Simple;


=head1 NAME

ShinyCMS::Controller::Admin::Newsletters - Catalyst Controller

=head1 DESCRIPTION

Controller for ShinyCMS newsletter admin features.

=head1 METHODS

=cut


=head2 index

Display a list of recent newsletters.

=cut

sub index : Path : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'list' );
}


=head2 base

Set up path and stash some useful stuff.

=cut

sub base : Chained( '/' ) : PathPart( 'admin/newsletters' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Admin::Newsletters';
}


=head2 get_element_types

Return a list of newsletter-element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this
	
	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
}


# ========== ( Newsletters ) ==========

=head2 list_newsletters

View a list of all newsletters.

=cut

sub list_newsletters : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view the list of newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'view the list of newsletters', 
		role   => 'Newsletter Admin',
	});
	
	# Fetch the list of newsletters
	my @newsletters = $c->model( 'DB::Newsletter' )->all;
	$c->{ stash }->{ newsletters } = \@newsletters;
}


=head2 add_newsletter

Add a new newsletter.

=cut

sub add_newsletter : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a newsletter', 
		role     => 'Newsletter Admin',
		redirect => $c->uri_for
	});
	
	# Fetch the list of available templates
	my @templates = $c->model( 'DB::NewsletterTemplate' )->all;
	$c->{ stash }->{ templates } = \@templates;
	
	# Set the TT template to use
	$c->stash->{template} = 'admin/newsletters/edit_newsletter.tt';
}


=head2 add_newsletter_do

Process a newsletter addition.

=cut

sub add_newsletter_do : Chained( 'base' ) : PathPart( 'add-newsletter-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a newsletter', 
		role     => 'Newsletter Admin',
		redirect => $c->uri_for
	});
	
	# Extract page details from form
	my $details = {
		title    => $c->request->param( 'title'    ) || undef,
		template => $c->request->param( 'template' ) || undef,
	};
	
	# Sanitise the url_title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;
	$details->{ url_title } = $url_title || undef;
	
	# Create page
	my $newsletter = $c->model( 'DB::Newsletter' )->create( $details );
	
	# Set up newsletter elements
	my @elements = $newsletter->template->newsletter_template_elements->all;
	
	foreach my $element ( @elements ) {
		my $el = $newsletter->newsletter_elements->create({
			name => $element->name,
			type => $element->type,
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Newsletter added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $newsletter->id ) );
}


=head2 edit_newsletter

Edit a newsletter.

=cut

sub edit_newsletter : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $nl_id ) = @_;
	
	# Check to make sure user has the right to edit newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit a newsletter', 
		role     => 'Newsletter Admin', 
		redirect => $c->uri_for,
	});
	
	$c->stash->{ newsletter } = $c->model( 'DB::Newsletter' )->find({
		id => $nl_id,
	});
	
	$c->{ stash }->{ types  } = get_element_types();
	
	# Stash a list of images present in the images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'images' );
	
	# Get page elements
	my @elements = $c->model( 'DB::NewsletterElement' )->search({
		newsletter => $c->stash->{ newsletter }->id,
	});
	$c->stash->{ newsletter_elements } = \@elements;
	
	# Build up 'elements' structure for use in cms-templates
	foreach my $element ( @elements ) {
		$c->stash->{ elements }->{ $element->name } = $element->content;
	}
	
	# Fetch the list of available templates
	my @templates = $c->model('DB::NewsletterTemplate')->search;
	$c->{ stash }->{ templates } = \@templates;
}


=head2 edit_newsletter_do

Process a newsletter update.

=cut

sub edit_newsletter_do : Chained( 'base' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit a newsletter', 
		role     => 'Newsletter Admin', 
		redirect => $c->uri_for,
	});
	
	# Fetch the newsletter
	$c->stash->{ newsletter } = $c->model( 'DB::Newsletter' )->find({
		id => $c->request->param( 'newsletter_id' ),
	});
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ newsletter }->newsletter_elements->delete;
		$c->stash->{ newsletter }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Newsletter deleted';
		
		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}
	
	# Extract newsletter details from form
	my $details = {
		title => $c->request->param( 'title' ),
	};
	
	# Sanitise the url_title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;
	$details->{ url_title } = $url_title;
	
	# Add in the template ID if one was passed in
	$details->{ template } = $c->request->param( 'template' ) if $c->request->param( 'template' );
	
	# TODO: If template has changed, change element stack
	if ( $c->request->param( 'template' ) != $c->stash->{ newsletter }->template->id ) {
		# Fetch old element set
		# Fetch new element set
		# Find the difference between the two sets
		# Add missing elements
		# Remove superfluous elements? Probably not - keep in case of reverts.
	}
	
	# Extract newsletter elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'Newsletter Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'name'    } = $c->request->param( $input );
		}
		if ( $input =~ m/^type_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'Newsletter Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'type'    } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
		}
	}
	
	# Update newsletter
	my $newsletter = $c->stash->{ newsletter }->update( $details );
	
	# Update newsletter elements
	foreach my $element ( keys %$elements ) {
		$c->stash->{ newsletter }->newsletter_elements->find({
			id => $element,
		})->update( $elements->{ $element } );
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $newsletter->id ) );
}


=head2 send_now

Queue a newsletter for immediate delivery.

=cut

sub send_now : Chained( 'base' ) : PathPart( 'send' ) : Args( 1 ) {
	my ( $self, $c, $newsletter_id ) = @_;
	
	# Check to make sure user has the right to send newsletters
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'send a newsletter', 
		role     => 'Newsletter Admin', 
		redirect => $c->uri_for,
	});
	
	# Fetch the newsletter
	$c->stash->{ newsletter } = $c->model( 'DB::Newsletter' )->find({
		id => $newsletter_id,
	});
	
	# Set scheduled delivery date to 'now'
	$c->stash->{ newsletter }->update({ sent => \'current_timestamp' });
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Newsletter queued for sending';
	
	# Bounce back to the list
	$c->response->redirect( $c->uri_for( 'list' ) );
}



# ========== ( Mailing Lists ) ==========

=head2 list_lists

View a list of all mailing lists.

=cut

sub list_lists : Chained( 'base' ) : PathPart( 'list-lists' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view the list of mailing lists
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action => 'view all mailing lists', 
		role   => 'Newsletter Admin',
	});
	
	# Fetch the list of mailing lists
	my @lists = $c->model( 'DB::MailingList' )->all;
	$c->{ stash }->{ mailing_lists } = \@lists;
}


=head2 get_list

Stash details relating to a mailing list.

=cut

sub get_list : Chained( 'base' ) : PathPart( 'lists' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $list_id ) = @_;
	
	$c->stash->{ mailing_list } = $c->model( 'DB::MailingList' )->find( { id => $list_id } );
	
	unless ( $c->stash->{ mailing_list } ) {
		$c->flash->{ error_msg } = 
			'Specified mailing list not found - please select from the options below';
		$c->go( 'list_lists' );
	}
}


=head2 add_list

Add a new mailing list.

=cut

sub add_list : Chained( 'base' ) : PathPart( 'add-list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add mailing lists
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a new mailing list', 
		role     => 'Newsletter Admin',
		redirect => $c->uri_for
	});
	
	$c->stash->{ template } = 'admin/newsletters/edit_list.tt';
}


=head2 edit_list

Edit an existing mailing list.

=cut

sub edit_list : Chained( 'get_list' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit mailing lists
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit mailing lists', 
		role     => 'Newsletter Admin',
		redirect => $c->uri_for
	});
}


=head2 edit_list_do

Process a mailing list update or addition.

=cut

sub edit_list_do : Chained( 'base' ) : PathPart( 'edit-list-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit mailing lists
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit mailing lists', 
		role     => 'Newsletter Admin',
		redirect => $c->uri_for
	});
	
	my $list_id = $c->request->param( 'list_id' );
	$c->stash->{ mailing_list } = $c->model( 'DB::MailingList' )->find({
		id => $list_id,
	});
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ mailing_list }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'List deleted';
		
		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list-lists' ) );
		return;
	}
	
	if ( $c->request->param( 'list_id' ) ) {
		# Update existing list
		$c->stash->{ mailing_list }->update({
			name => $c->request->param( 'name' ),
		});
		
		# Extract uploaded datafile, if any
		my $datafile = $c->request->upload( 'datafile' );
		if ( $datafile ) {
			my $parser = Text::CSV::Simple->new;	# comma-separated
			#my $parser = Text::CSV::Simple->new({ sep_char => "\t" });	# tab-separated
			my @data = $parser->read_file( $datafile->fh );
			if ( @data ) {
				# Wipe the existing recipient list
				$c->stash->{ mailing_list }->list_recipients->delete;
			}
			else {
				# Reading in the CSV file went wrong
				warn "Error reading CSV file: $!";
			}
			foreach my $row ( @data ) {
				next unless $row->[1];
				my $recipient = $c->model( 'DB::MailRecipient' )->create({
					name  => $row->[0],
					email => $row->[1],
				});
				$c->stash->{ mailing_list }->list_recipients->create({
					recipient => $recipient->id,
				});
			}
		}
	}
	else {
		# Create new list
		$c->stash->{ mailing_list } = $c->model( 'DB::MailingList' )->create({
			name => $c->request->param( 'name' ),
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'List details saved';
	
	# Bounce back to the edit page
	$c->response->redirect( $c->uri_for( 'lists', $c->stash->{ mailing_list }->id, 'edit' ) );
}



# ========== ( Templates ) ==========

=head2 list_templates

List all the newsletter templates.

=cut

sub list_templates : Chained( 'base' ) : PathPart( 'list-templates' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in and a newsletter admin
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'list newsletter templates', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	my @templates = $c->model( 'DB::NewsletterTemplate' )->all;
	$c->stash->{ newsletter_templates } = \@templates;
}


=head2 get_template

Stash details relating to a CMS template.

=cut

sub get_template : Chained( 'base' ) : PathPart( 'template' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $template_id ) = @_;
	
	$c->stash->{ newsletter_template } = $c->model( 'DB::NewsletterTemplate' )->find( { id => $template_id } );
	
	unless ( $c->stash->{ newsletter_template } ) {
		$c->flash->{ error_msg } = 
			'Specified template not found - please select from the options below';
		$c->go( 'list_templates' );
	}
	
	# Get template elements
	my @elements = $c->model( 'DB::NewsletterTemplateElement' )->search( {
		template => $c->stash->{ newsletter_template }->id,
	} );
	
	$c->stash->{ template_elements } = \@elements;
}


=head2 get_template_filenames

Get a list of available template filenames.

=cut

sub get_template_filenames {
	my ( $c ) = @_;
	
	my $template_dir = $c->path_to( 'root/newsletters/newsletter-templates' );
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

Add a new newsletter template.

=cut

sub add_template : Chained( 'base' ) : PathPart( 'add-template' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a new template', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	$c->{ stash }->{ template_filenames } = get_template_filenames( $c );
	
	$c->{ stash }->{ types  } = get_element_types();
	
	$c->stash->{ template } = 'admin/newsletters/edit_template.tt';
}


=head2 add_template_do

Process a template addition.

=cut

sub add_template_do : Chained( 'base' ) : PathPart( 'add-template-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a new template', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	# Create template
	my $template = $c->model( 'DB::NewsletterTemplate' )->create({
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

sub edit_template : Chained( 'get_template' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c, $template_id ) = @_;
	
	# Bounce if user isn't logged in and a newsletter admin
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit a template', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	$c->{ stash }->{ types  } = get_element_types();
	
	$c->{ stash }->{ template_filenames } = get_template_filenames( $c );
}


=head2 edit_template_do

Process a template edit.

=cut

sub edit_template_do : Chained( 'base' ) : PathPart( 'edit-template-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit newsletter templates
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit a template', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	my $template_id = $c->request->param( 'template_id' );
	$c->stash->{ newsletter_template } = $c->model( 'DB::NewsletterTemplate' )->find({
		id => $template_id,
	});
	
	# Process deletions
	if ( $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ newsletter_template }->newsletter_template_elements->delete;
		$c->stash->{ newsletter_template }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Template deleted';
		
		# Bounce to the 'view all templates' page
		$c->response->redirect( $c->uri_for( 'list-templates' ) );
		return;
	}
	
	# Update template
	$c->stash->{ newsletter_template }->update({
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

sub add_template_element_do : Chained( 'get_template' ) : PathPart( 'add-template-element-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add template elements
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add a new element to a newsletter template', 
		role     => 'Newsletter Template Admin',
		redirect => $c->uri_for
	});
	
	# Extract element from form
	my $element = $c->request->param( 'new_element' );
	my $type    = $c->request->param( 'new_type'    );
	
	# Update the database
	$c->model( 'DB::NewsletterTemplateElement' )->create({
		template => $c->stash->{ newsletter_template }->id,
		name     => $element,
		type     => $type,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'template', $c->stash->{ newsletter_template }->id, 'edit' ) );
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

