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

	my $day = DateTime->now->add( days => 1 );
	my $data = {
		labels       => [],
		daily_logins => [],
		new_users    => [],
		new_members  => [],
		renewals     => [],
		income       => [],
    };
	foreach ( 1..7 ) {
		my $tom = $day->clone;
		$day->subtract( days => 1 );
		
		# Labels ('Monday 31 March')
		unshift @{ $data->{ labels } }, $day->day_abbr . ' ' . $day->day . ' ' . $day->month_abbr;

		# All visitors
		my $visitors = $c->model('DB::Session')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ visitors } }, $visitors;
		# User logins
		my $logins = $c->model('DB::UserLogin')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ logins } }, $logins;
		# New users
		my $new_users = $c->model('DB::User')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ new_users } }, $new_users;

		# New members
		my $new_members = $c->model('DB::UserAccess')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ new_members } }, $new_members;
		# Renewals
		my $day30 = $day->clone->add( days => 30 );
		my $day60 = $day->clone->add( days => 60 );
		my $renewals = $c->model('DB::UserAccess')->search({
			created => { '<' => $day->ymd },
			expires => { '>=' => $day30->ymd, '<=' => $day60->ymd },
		})->count;
		unshift @{ $data->{ renewals } }, $renewals;
		# Income
		my $fee = 30;	# TODO: config item for this
		unshift @{ $data->{ income } }, ( ( $new_members + $renewals ) * $fee );
	}

	$c->stash->{ dashboard } = $data;
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
