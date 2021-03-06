package ShinyCMS::Controller::Admin::Dashboard;

use Moose;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Dashboard

=head1 DESCRIPTION

ShinyCMS admin dashboard.

=cut


has access_subscription_fee => (
	isa     => Int,
	is      => 'ro',
	default => 10,
);

has currency_symbol => (
	isa     => Str,
	is      => 'ro',
	default => '&pound;',
);


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

sub dashboard : Chained( 'base' ) : PathPart( '' ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view admin dashboard',
		role     => 'User Admin', # TODO
		redirect => '/'
	});

	# Figure out what date we're looking at stats for
	my $day;
	if ( $c->request->param('date') and $c->request->param('date') =~ m{(\d\d\d\d)\-(\d\d)\-(\d\d)} ) {
		$day = DateTime->new(
			year  => $1,
			month => $2,
			day   => $3,
		);
	}
	$day = DateTime->now unless $day;
	my $current = $day->date eq DateTime->now->date ? 1 : 0;

	my $data = {
		labels       => [],

		daily_logins => [],
		new_users    => [],
		new_members  => [],

		renewals     => [],
		income       => [],

		likes        => [],
		comments     => [],
		forum_posts  => [],
    };

	# TODO: This is horrible; it should pull all 7 days in a single query
	foreach ( 1..7 ) {
		my $tom = $day->clone->add( days => 1 );

		# Labels ('Monday 31 March')
		unshift @{ $data->{ labels } },
			$day->day_name . ' ' . $day->day . ' ' . $day->month_name;

		# All visitors
		my $visitors = $c->model('DB::Session')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ visitors } }, $visitors;
		$data->{ visitors_total } += $visitors;
		# User logins
		my $logins = $c->model('DB::UserLogin')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ logins } }, $logins;
		$data->{ logins_total } += $logins;
		# New users
		my $new_users = $c->model('DB::User')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ new_users } }, $new_users;
		$data->{ new_users_total } += $new_users;

		# New members
		my $new_members = $c->model('DB::UserAccess')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ new_members } }, $new_members;
		$data->{ new_members_total } += $new_members;
		# Renewals
		my $day30 = $day->clone->add( days => 30 );
		my $day31 = $day->clone->add( days => 31 );
		my $renewals = $c->model('DB::UserAccess')->search({
			created => { '<' => $day->ymd },
			expires => { '>' => $day30->ymd, '<' => $day31->ymd },
		})->count;
		unshift @{ $data->{ renewals } }, $renewals;
		$data->{ renewals_total } += $renewals;
		# Income
		my $income = $self->access_subscription_fee * ( $new_members + $renewals );
		unshift @{ $data->{ income } }, $income;
		$data->{ income_total } += $income;

		# Likes (comment + shop_item)
		my $likes = $c->model('DB::CommentLike')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		$likes += $c->model('DB::ShopItemLike')->search({
			created => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ likes } }, $likes;
		$data->{ likes_total } += $likes;
		# Comments
		my $comments = $c->model('DB::Comment')->search({
			posted => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ comments } }, $comments;
		$data->{ comments_total } += $comments;
		# Forum Posts
		my $forum_posts = $c->model('DB::ForumPost')->search({
			posted => { '>' => $day->ymd, '<' => $tom->ymd },
		})->count;
		unshift @{ $data->{ forum_posts } }, $forum_posts;
		$data->{ forum_posts_total } += $forum_posts;

		$day->subtract( days => 1 );
	}
	# Get previous week's totals, for comparison
	$day->add( days => 1 );
	my $prev_start = $day->clone->subtract( days => 7 );
	$data->{ visitors_prev } = $c->model('DB::Session')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ logins_prev } = $c->model('DB::UserLogin')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ new_users_prev } = $c->model('DB::User')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ new_members_prev } = $c->model('DB::UserAccess')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	# TODO: Renewals and Income figures assume 30 day subscription, one price
	my $day30 = $prev_start->clone->add( days => 30 );
	my $day37 = $prev_start->clone->add( days => 37 );
	$data->{ renewals_prev } = $c->model('DB::UserAccess')->search({
		created => { '<' => $prev_start->ymd },
		expires => { '>' => $day30->ymd, '<' => $day37->ymd },
	})->count;
	$data->{ income_prev } = $self->access_subscription_fee
		* ( $data->{ new_members_prev } + $data->{ renewals_prev } );
	$data->{ likes_prev } += $c->model('DB::ShopItemLike')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ comments_prev } = $c->model('DB::Comment')->search({
		posted => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ likes_prev } = $c->model('DB::CommentLike')->search({
		created => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;
	$data->{ forum_posts_prev } = $c->model('DB::ForumPost')->search({
		posted => { '>' => $prev_start->ymd, '<' => $day->ymd },
	})->count;

	my $prev_week = $day->clone->subtract( days =>  1 );
	my $next_week = $day->clone->add(      days => 13 );

	$c->stash->{ dashboard } = $data;
	$c->stash->{ this_week } = $day unless $current;
	$c->stash->{ prev_week } = $prev_week->ymd;
	$c->stash->{ next_week } = $next_week->ymd unless $current;

	$c->stash->{ currency_symbol } = $self->currency_symbol;
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
