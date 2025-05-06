package ShinyCMS::Controller::Admin::Events;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Events

=head1 DESCRIPTION

Controller for ShinyCMS events admin features.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);


=head1 METHODS

=head2 base

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/events' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'add/edit/delete events',
		role     => 'Events Admin',
		redirect => '/events'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Events';
}


=head2 index

Forward to the list of events

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_events' );
}


=head2 list_events

List all events

=cut

sub list_events : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $events = $c->model( 'DB::Event' )->search(
		{},
		{
			order_by => { -desc => [ 'start_date', 'end_date' ] },
			rows     => $self->page_size,
			page     => $self->safe_param( $c, 'page', 1 ),
		}
	);

	$c->stash->{ events } = $events;
}


=head2 add_event

Add a new event

=cut

sub add_event : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash a list of images present in the event-images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'event-images' );

	$c->stash->{ template } = 'admin/events/edit_event.tt';
}


=head2 edit_event

Edit an existing event

=cut

sub edit_event : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $event_id ) = @_;

	# Stash a list of images present in the event-images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'event-images' );

	$c->stash->{ event  } = $c->model( 'DB::Event' )->find({
		id => $event_id,
	});
}


=head2 add_event_do

Process adding an event

=cut

sub add_event_do : Chained( 'base' ) : PathPart( 'add-event-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );

	# KBAKER 20250506: MySQL to PostgreSQL migration, if dates of proper form are not entered,
	# ask user to fill out a start date/time and end date/time.
	if ($start_date !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/ 
			|| $end_date !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/
	) {
		$c->flash->{ error_msg } = 'Must fill out start and end date and start and end time';
		$c->response->redirect( $c->uri_for( '/admin/events/add' ) );
		$c->detach();
		return;
	}

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
		$c->request->param( 'url_name' ) :
		$c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Add the item
	my $item = $c->model( 'DB::Event' )->create({
		name         => $c->request->param( 'name'         ),
		url_name     => $url_name,
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		start_date   => $start_date,
		end_date     => $end_date,
		address      => $self->safe_param( $c, 'address',  '' ),
		postcode     => $self->safe_param( $c, 'postcode', '' ),
		email        => $c->request->param( 'email'        ),
		link         => $c->request->param( 'link'         ),
		booking_link => $c->request->param( 'booking_link' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Event added';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
}


=head2 edit_event_do

Process editing an event

=cut

sub edit_event_do : Chained( 'base' ) : PathPart( 'edit-event-do' ) : Args( 1 ) {
	my ( $self, $c, $event_id ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->model( 'DB::Event' )->search({ id => $event_id })->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Event deleted';

		# Bounce to the default page
		$c->response->redirect( $c->uri_for( '/admin/events' ) );
		return;
	}

	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );

	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Add the item
	my $item = $c->model( 'DB::Event' )->find({
		id => $event_id,
	})->update({
		name         => $c->request->param( 'name'         ),
		url_name     => $url_name,
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		start_date   => $start_date,
		end_date     => $end_date,
		address      => $self->safe_param( $c, 'address',  '' ),
		postcode     => $self->safe_param( $c, 'postcode', '' ),
		email        => $c->request->param( 'email'        ),
		link         => $c->request->param( 'link'         ),
		booking_link => $c->request->param( 'booking_link' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Event updated';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( '/admin/events/edit', $item->id ) );
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
