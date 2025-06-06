package ShinyCMS::Controller::Polls;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Polls

=head1 DESCRIPTION

Controller for ShinyCMS polls.

=head1 METHODS

=cut



=head2 base

Base method, sets up path.

=cut

sub base : Chained( '/base' ) : PathPart( 'polls' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the name of the controller
	$c->stash->{ controller } = 'Polls';
}


=head2 view_polls

View polls.

=cut

sub view_polls : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @polls = $c->model( 'DB::PollQuestion' )->search(
		{},
		{
			order_by => { -desc => 'id' },
		},
	);

	$c->stash->{ polls } = \@polls;
}


=head2 view_poll

View a poll.

=cut

sub view_poll : PathPart( '' ) : Chained( 'base' ) : Args( 1 ) {
	my ( $self, $c, $poll_id ) = @_;

	$c->stash->{ poll } = $c->model( 'DB::PollQuestion' )->find({
		id => $poll_id,
	});
}


=head2 vote

Vote in a poll.

=cut

sub vote : Chained( 'base' ) : PathPart( 'vote' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $poll = $c->model( 'DB::PollQuestion' )->find({
		id => $c->request->param( 'poll' ),
	});

	if ( $c->user_exists ) {
		# Logged-in user voting
		# KBAKER 20250516: MySQL to PostgreSQL migration, was searching for 'user' in database
		# -> changed to 'user_id' as 'user' is a reserved word in postgres.
		my $existing_vote = $poll->poll_user_votes->find({
			user_id => $c->user->id,
		});

		# KBAKER 20250602: general debugging, prevents users from voting if poll has no available
		# answers they can vote on
		my $answer = $c->request->param( 'answer' );
		if( ! $answer ) {
			$c->flash->{ error_msg } = 'Poll must have at least one answer to vote';
			$c->response->redirect( $c->uri_for( $poll->id ) );
			$c->detach();
			return;
		}

		if ( $existing_vote ) {
			if ( $c->request->param( 'answer' ) == $existing_vote->answer->id ) {
				$c->flash->{ status_msg } = 'You have already voted for \''.
					$existing_vote->answer->answer .'\' in this poll.';
			}
			else {
				$c->flash->{ status_msg } = 'You had already voted in this poll, for \''.
					$existing_vote->answer->answer .
					'\'.  Your vote has now been changed to \''.
					$poll->poll_answers->find({
						id => $c->request->param( 'answer' ),
					})->answer .'\'.';
				$existing_vote->update({
					answer     => $c->request->param( 'answer' ),
					ip_address => $c->request->address,
				});
			}
		}
		else {
			# Check for an anonymous vote from this IP address
			my $anon_vote = $poll->poll_anon_votes->find({
				ip_address => $c->request->address,
			});
			if ( $anon_vote ) {
				# Remove the anon vote if one exists
				$c->flash->{ status_msg } = 'Somebody from your IP address had '.
					'already voted anonymously in this poll, for \''.
					$anon_vote->answer->answer .
					'\'.  That vote has been replaced by your vote for \''.
					$poll->poll_answers->find({
						id => $c->request->param( 'answer' ),
					})->answer .'\'.';
				$anon_vote->delete;
			}
			# Store the user-linked vote
			# KBAKER 20250516: MySQL to PostgreSQL migration, was searching for 'user' in database
			# -> changed to 'user_id' as 'user' is a reserved word in postgres.
			$poll->poll_user_votes->create({
				answer     => $c->request->param( 'answer' ),
				user_id       => $c->user->id,
				ip_address => $c->request->address,
			});
		}
	}
	else {
		# Anonymous vote
		my $anon_vote = $poll->poll_anon_votes->find({
			ip_address => $c->request->address,
		});
		my $user_vote = $poll->poll_user_votes->find({
			ip_address => $c->request->address,
		});
		if ( $anon_vote or $user_vote ) {
			# Return an 'already voted' error
			$c->flash->{ error_msg } =
				'Somebody with your IP address has already voted in this poll.';
		}
		else {
			# Add the vote
			$poll->poll_anon_votes->create({
				answer     => $c->request->param( 'answer' ),
				ip_address => $c->request->address,
			});
		}
	}

	$c->response->redirect( $c->uri_for( $poll->id ) );
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
