# ===================================================================
# File:		t/schema-results/User.t
# Project:	ShinyCMS
# Purpose:	Tests for user model
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

# Get a schema object
my $schema = get_schema();

# Create a test user
my $user = create_test_user( 'test_user_model' );

# Test for membership of an access group that doesn't exist
ok(
	not ( defined $user->access_expires( 'Test' ) ),
	"User does not have 'Test' access"
);

# Give the test user some access
my $eternal_access = $schema->resultset( 'Access' )->search({
	access => 'Eternal'
})->single;
$user->user_accesses->find_or_create({ access => $eternal_access->id });
my $current_access = $schema->resultset( 'Access' )->search({
	access => 'Unexpired'
})->single;
$user->user_accesses->find_or_create({ access => $current_access->id });
my $expired_access = $schema->resultset( 'Access' )->search({
	access => 'Expired'
})->single;
$user->user_accesses->update_or_create({ access => $expired_access->id, expires => '2001-01-01' });

# Test what they can reach now
ok(
	$user->access_expires( 'Eternal' ),
	"User has/had 'Eternal' access"
);
ok(
	$user->access_expires( 'Unexpired' ),
	"User has/had 'Unexpired' access"
);
ok(
	$user->access_expires( 'Expired' ),
	"User has/had 'Expired' access"
);
ok(
	not ( defined $user->access_expires( 'Exclusive' ) ),
	"User has never had 'Exclusive' access"
);
ok(
	$user->has_access( 'Eternal' ),
	'Eternal access is currently valid'
);
ok(
	$user->has_access( 'Unexpired' ),
	'Unexpired access is currently valid'
);
ok(
	not ( $user->has_access( 'Expired' ) ),
	'Expired access is not currently valid'
);
ok(
	not ( $user->has_access( 'Exclusive' ) ),
	"Exclusive access is not currently valid"
);
# Various content counters
ok(
	$user->blog_post_count == 0,
	'User has zero blog posts'
);
ok(
	$user->forum_post_count == 0,
	'User has zero forum posts'
);
ok(
	$user->comment_count == 0,
	'User has zero comments'
);
ok(
	$user->forum_post_and_comment_count == 0,
	'User has zero forum posts and comments'
);
# Blog post author
my $blogger = $schema->resultset( 'BlogPost' )->first->author;
my $blogs   = $schema->resultset( 'BlogPost' )->count({ author => $blogger->id });
ok(
	$blogger->blog_post_count == $blogs,
	"Blog post author has $blogs blog posts"
);
my $recent_blog_posts = $blogger->recent_blog_posts;
ok(
	ref $recent_blog_posts->first eq 'ShinyCMS::Schema::Result::BlogPost',
	'Fetched recent blog posts by user'
);
# Forum post author
my $poster = $schema->resultset( 'ForumPost' )->first->author;
my $posts  = $schema->resultset( 'ForumPost' )->count({ author => $poster->id });
ok(
	$poster->forum_post_count == $posts,
	"Forum post author has $posts forum posts"
);
my $recent_forum_posts = $poster->recent_forum_posts;
ok(
	ref $recent_forum_posts->first eq 'ShinyCMS::Schema::Result::ForumPost',
	'Fetched recent forum posts by user'
);
# Comment author
my $commenter = $schema->resultset( 'Comment' )->first->author;
my $comments  = $schema->resultset( 'Comment' )->count({ author => $commenter->id });
ok(
	$commenter->comment_count == $comments,
	"Comment author has $comments comments"
);
my $recent_comments = $commenter->recent_comments;
ok(
	ref $recent_comments->first eq 'ShinyCMS::Schema::Result::Comment',
	'Fetched recent comments by user'
);

done_testing();
