package ShinyCMS::Controller::Forums;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Forums

=head1 DESCRIPTION

Controller for ShinyCMS forums.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);


=head1 METHODS

=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/base' ) : PathPart( 'forums' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the name of the controller
	$c->stash->{ controller } = 'Forums';
}


=head2 view_forums

Display all sections and forums.

=cut

sub view_forums : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	#my @sections = $c->model( 'DB::ForumSection' )->all;
	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{
			order_by => 'display_order',
		},
	)->all;

	$c->stash->{ forum_sections } = \@sections;
}


=head2 view_section

Display the list of forums in a specified section.

=cut

sub view_section : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $section ) = @_;

	$c->stash->{ section } = $c->model( 'DB::ForumSection' )->find({
		url_name => $section,
	});

	# KBaker 20250530: general debugging, added checking if section exists
	if( !$c->stash->{ section } ) {
		$c->flash->{ error_msg } = 'Section not found';
		$c->response->redirect( $c->uri_for( '/forums/post/', $section) );
		$c->detach();
		return;
	}

	my @forums = $c->stash->{ section }->sorted_forums;

	$c->stash->{ forum_sections } = \@forums;
}


=head2 view_tag

Display a page of forum posts with a particular tag.

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;

	my $page  = int ( $c->request->param( 'page'  ) || 1 );
	my $count = int ( $c->request->param( 'count' ) || $self->page_size );

	my $posts = $self->get_tagged_posts( $c, $tag, $page, $count );

	$c->stash->{ tag         } = $tag;
	$c->stash->{ page_num    } = $page;
	$c->stash->{ post_count  } = $count;
	$c->stash->{ forum_posts } = $posts;

	$c->stash->{ template    } = 'forums/view_forum.tt';
}


=head2 view_forum

Display first page of posts in a specified forum.

=cut

sub view_forum : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $section_name, $forum_name ) = @_;

	$c->stash->{ section } = $c->model( 'DB::ForumSection' )->search({
		url_name => $section_name,
	})->first;
	$c->stash->{ forum } = $c->stash->{ section }->forums->search({
		url_name => $forum_name,
	})->first;

	my $count = $c->request->param( 'count' ) ?
				$c->request->param( 'count' ) : $self->page_size;
	my $page  = $c->request->param( 'page'  ) ?
				$c->request->param( 'page'  ) : 1;

	$c->stash->{ sticky_posts } = $c->stash->{ forum }->sticky_posts->search(
		{},
		{
			page => $page,
			rows => $count,
		}
	);
	$c->stash->{ forum_posts } = $c->stash->{ forum }->non_sticky_posts->search(
		{},
		{
			order_by => [ { -desc => 'commented_on' }, { -desc => 'posted' } ],
			page     => $page,
			rows     => $count,
		}
	);

	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
}


=head2 view_posts_by_author

Display a page of forum posts by a particular author.

=cut

sub view_posts_by_author : Chained( 'base' ) : PathPart( 'author' ) : Args( 1 ) {
	my ( $self, $c, $author ) = @_;

	my $page  = int ( $c->request->param( 'page'  ) || 1 );
	my $count = int ( $c->request->param( 'count' ) || $self->page_size );

	my $posts = $self->get_posts_by_author( $c, $author, $page, $count );

	$c->stash->{ author      } = $author;
	$c->stash->{ page_num    } = $page;
	$c->stash->{ post_count  } = $count;
	$c->stash->{ forum_posts } = $posts;

	$c->stash->{ template    } = 'forums/view_forum.tt';
}


=head2 view_post

View a specified forum post.

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 4 ) {
	my ( $self, $c, $section_name, $forum_name, $post_id, $url_title ) = @_;

	my $post = $self->get_post( $c, $post_id );

	# Make sure we found the specified post
	unless ( $post ) {
		$c->stash->{ error_msg } = 'Failed to find specified forum post.';
		$c->go( 'view_forums' );
	}

	# Check url_title matches post, if it doesn't then redirect to correct URL
	unless ( $post->url_title eq $url_title ) {
		$c->response->redirect( $c->uri_for(
			$post->forum->section->url_name, $post->forum->url_name,
			$post->id, $post->url_title
		) );
	}

	# Stash the post
	$c->stash->{ forum_post } = $post;

	# Stash the tags
	$c->stash->{ forum_post }->{ tags } = $self->get_tags( $c, $c->stash->{ forum_post }->id );
}


=head2 add_post

Start a new thread.

=cut

sub add_post : Chained( 'base' ) : PathPart( 'post' ) : Args( 2 ) {
	my ( $self, $c, $section_name, $forum_name ) = @_;

	# KBAKER 20250530: general debugging, adding $section_name and $forum_name to the stash for use
	# in add_post_do()
	$c->stash->{ section_name } = $section_name;
	$c->stash->{ forum_name } = $forum_name;

	# Check to make sure we have a logged-in user
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to post on the forums.';
		$c->go( '/login' );
	}

	my $section = $c->model( 'DB::ForumSection' )->find({
		url_name => $section_name,
	});
	$c->stash->{ forum } = $section->forums->find({
		url_name => $forum_name,
	});

	$c->stash->{ template } = 'forums/edit_post.tt';
}


=head2 add_post_do

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'add-post-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure we have a logged-in user
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to post on the forums.';
		$c->go( '/login' );
	}

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' ) ?
	    $c->request->param( 'url_title' ) :
	    $c->request->param( 'title'     );
	$url_title = $self->make_url_slug( $url_title );

	# Filter the body text
	my $body = $c->request->param( 'body' );
	$body    = $c->model( 'FilterHTML' )->filter( $body );

	# KBAKER: general debugging, added checking for required fields for post
	my $section_name = $c->request->param( 'section_name' );
	my $forum_name = $c->request->param( 'forum_name' );
	if ( !$body ) {
		$c->flash->{ error_msg } = 'Need to add a body.';
		$c->response->redirect( $c->uri_for( "/forums/post/$section_name/$forum_name" ) );
		$c->detach();
		return;
	}

	my $title = $c->request->param( 'title' );
	if( !$title ) {
		$c->flash->{ error_msg } = 'Need to add a title.';
		$c->response->redirect( $c->uri_for( "/forums/post/$section_name/$forum_name" ) );
		$c->detach();
		return;
	}

	# Add the post
	my $post = $c->model( 'DB::ForumPost' )->create({
		author    => $c->user->id,
		title     => $title,
		url_title => $url_title,
		body      => $body,
		forum     => $c->request->param( 'forum' ),
	});

	# Create a related discussion thread
	my $discussion = $c->model( 'DB::Discussion' )->create({
		resource_id   => $post->id,
		resource_type => 'ForumPost',
	});
	$post->update({ discussion => $discussion->id });

	# Process the tags
	if ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'ForumPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'New thread added';

	# Bounce to the newly-posted item
	$c->response->redirect( $c->uri_for( $post->forum->section->url_name,
		$post->forum->url_name, $post->id, $post->url_title ) );
}


# ========== ( utility methods ) ==========

=head2 get_post

=cut

sub get_post : Private {
	my ( $self, $c, $post_id ) = @_;

	return $c->model( 'DB::ForumPost' )->find({
		id => $post_id,
	});
}


=head2 get_tags

Get the tags for a post

=cut

sub get_tags : Private {
	my ( $self, $c, $post_id ) = @_;

	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $post_id,
		resource_type => 'ForumPost',
	});

	return $tagset->tag_list if $tagset;
}


=head2 get_tagged_posts

Get a page's worth of posts with a particular tag

=cut

sub get_tagged_posts : Private {
	my ( $self, $c, $tag, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : $self->page_size;

	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'ForumPost';
		push @tagged, $tagset->get_column( 'resource_id' ),
	}

	return $c->model( 'DB::ForumPost' )->search(
		{
			id       => { 'in' => \@tagged },
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
}


=head2 get_posts_by_author

Get a page's worth of posts by a particular author

=cut

sub get_posts_by_author : Private {
	my ( $self, $c, $username, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : $self->page_size;

	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});

	return $c->model( 'DB::ForumPost' )->search(
		{
			author   => $author->id,
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		}
	);
}


=head2 most_recent_comment

Return most recent comment posted in the forums.

=cut

sub most_recent_comment : Private {
	my( $self, $c ) = @_;

	# Find the most recent comment
	my $comment = $c->model( 'DB::Comment' )->search(
		{
			'discussion.resource_type' => 'ForumPost',
		},
		{
			order_by => { -desc => 'posted' },
			rows     => 1,
			join     => 'discussion',
		}
	)->single;

	return unless $comment;

	my $post = $c->model( 'DB::ForumPost' )->find({
		id => $comment->discussion->resource_id,
	});
	$comment->{ post } = $post;

	return $comment;
}


=head2 most_popular_comment

Return most popular comment in specified forum section.

TODO:
(a) This code is really ganky.
(b) I think it has a massive logic error right at the start (of both halves).
    How do I know the comments I find are on forum threads rather than blogs?

=cut

sub most_popular_comment : Private {
	my( $self, $c, $section_id ) = @_;

	if ( $section_id ) {
		# Find the most popular comment in this section
		my $likes = $c->model( 'DB::CommentLike' )->search(
			{},
			{
				'+select' => [

					{ count => 'id', -as => 'rowcount' }
				],
				group_by => 'comment',
				order_by => { -desc => 'rowcount' },
			},
		);

		while ( my $like = $likes->next ) {
			my $comment = $like->comment;

			my $post = $c->model( 'DB::ForumPost' )->find({
				id => $comment->discussion->resource_id,
			});

			if ( $post->forum->section->id == $section_id ) {
				$comment->{ post } = $post;
				return $comment;
			}
		}
		return;		# no popular comments in this section
	}
	else {
		# Find the most popular comment in any section
		my $result = $c->model( 'DB::CommentLike' )->search(
			{},
			{
				'+select' => [ { count => 'comment', -as => 'rowcount' } ],
				group_by  => [ 'comment', 'id', 'user', 'ip_address', 'created' ],
				order_by  => { -desc => 'rowcount' },
				rows      => 1,
			},
		)->single;

		return unless $result;	# no popular comments

		my $comment = $result->comment;

		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $comment->discussion->resource_id,
		});
		$comment->{ post } = $post;

		return $comment;
	}
}


=head2 get_top_posters

Return specified number of most prolific posters.

=cut

sub get_top_posters : Private {
	my( $self, $c, $count ) = @_;

	$count = $count ? $count : 10;

	# Get the user details from the db
#	my @users = $c->model( 'DB::User' )->search(
#		{},
#		{
#			order_by => 'forum_post_and_comment_count',
#			rows => $count,
#		},
#	);
#
#	return @users;

	my @users = $c->model( 'DB::User' )->all;

	@users = sort {
		$b->forum_post_and_comment_count <=> $a->forum_post_and_comment_count
	} @users;

	return @users[ 0 .. $count-1 ];
}


# ========== ( search method used by site-wide search feature ) ==========

=head2 search

Search the forums.

=cut

sub search {
	my ( $self, $c ) = @_;

	return unless my $search = $c->request->param( 'search' );

	my @results = $c->model( 'DB::ForumPost' )->search({
		-and => [
			posted => { '<=' => \'current_timestamp' },
			hidden => 0,
			-or => [
				title => { 'LIKE', '%'.$search.'%'},
				body  => { 'LIKE', '%'.$search.'%'},
			],
		],
	})->all;

	my $forum_posts = [];
	foreach my $result ( @results ) {
		# Pull out the matching search term and its immediate context
		my $match = '';
		if ( $result->title =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		# Tidy up and mark the truncation
		unless ( $match eq $result->title or $match eq $result->body ) {
			$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
			$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
		}
		if ( $match eq $result->title ) {
			$match = substr $result->body, 0, 100;
			$match =~ s/\s\S+\s?$/ .../;
		}
		# Add the match string to the result
		$result->{ match } = $match;

		# Push the result onto the results array
		push @$forum_posts, $result;
	}

	$c->stash->{ forum_results } = $forum_posts;
	return $forum_posts;
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

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
