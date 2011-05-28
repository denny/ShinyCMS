package ShinyCMS::Model::FilterHTML;

use Moose;
use namespace::clean -except => 'meta';

extends qw/ ShinyCMS::Model::Base /;


use HTML::Restrict;


=head1 NAME

ShinyCMS::Model::FilterHTML

=head1 DESCRIPTION

HTML-filtering model class for ShinyCMS

=cut


=head1 METHODS

=head2 defang

=cut

sub defang {
	my( $self, $html, $type ) = @_;
	
	# TODO: Fetch list of allowed tags and attributes from config
	# TODO: Use $type to pick an allowed-tag list, otherwise use the default
	
	# Create a HTML::Restrict object
	my $hr = HTML::Restrict->new;
	
	# Feed in the list of allowed tags and attributes
	$hr->set_rules({
		b      => [],
		strong => [],
		i      => [],
		em     => [],
		small  => [],
		p      => [],
		br     => [ qw ( / ) ],
		a      => [ qw( href title ) ],
#		img    => [ qw( src alt title width height / ) ]
	});
	
	# Pass the HTML through it
	my $defanged = $hr->process( $html );
	
	# Return the defanged HTML
	return $defanged;
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

