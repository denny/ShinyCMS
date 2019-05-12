package ShinyCMS::Controller::Admin::Dashboard;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Dashboard

=head1 DESCRIPTION

ShinyCMS admin dashboard.

=cut


#has config_item => (
#	isa     => Int,
#	is      => 'ro',
#	default => 10,
#);


=head1 METHODS

=cut


=head2 base

Set up the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/dashboard' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Dashboard';
}


=head2 dashboard

Display admin dashboard

=cut

sub dashboard : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view admin dashboard',
		role     => 'User Admin', # TODO
		redirect => '/'
	});

	# Find the dates for the last 7 days
	my $day = DateTime->now;
	my @labels;
	my @data;
	foreach ( 1..7 ) {
		push @labels, $day->day_abbr . ' ' . $day->day . ' ' . $day->month_abbr;
		my $tom = $day->clone->add( days => 1 );
		my $logins = $c->model('DB::Session')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		push @data, $logins;
		$day->subtract( days => 1 );
	}
	@labels = reverse @labels;
	@data = reverse @data;

	my $members_online = {
		labels => \@labels,
		data   => \@data,
	};

	$c->stash->{ dashboard }->{ members_online } = $members_online;
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
