# ===================================================================
# File:	    t/support/database_helper.pl
# Project:	ShinyCMS
# Purpose:	Helper methods for inserting or removing database data for testing
#
# Author:	Kai Baker <eigenspaces@gmail.com>
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;
use FindBin;
use File::Spec;
use Cwd 'abs_path';

# KBAKER 20250919: copied the next five lines below from file 'bin/database/data/insert-fileserver-demo-data';
# Load local helper lib and get connected schema object
use FindBin qw( $Bin );
use lib "$Bin/../../lib";
require 'helpers.pl';  ## no critic
my $schema = get_schema();

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..', '..'));

sub insert_forum_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-forums-demo-data');
    
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20250822: added feature, created delete_forums_data() to run the perl script delete-forums-demo-data
sub delete_forums_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'delete-forums-demo-data');
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

sub insert_required_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-required-data');
    
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}
# KBAKER20250829: created verify_forums_cleanup() to run Perl script that verifies forums demo data was removed
sub verify_forums_cleanup() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'verify_forum_cleanup');
    
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20250919: created insert_fileserver_data() to run Perl script that inserts FileServer demo data
sub insert_fileserver_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-fileserver-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20250923: created delete_fileserver_data() to run Perl script that deletes FileServer demo data
sub delete_fileserver_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'delete-fileserver-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20250923: created verify_fileserver_cleanup() to run Perl script that verifies deletion of FileServer demo data
sub verify_fileserver_cleanup() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'verify-fileserver-cleanup');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20251007: created insert_blog_data() to run Perl script that inserts blog demo data
sub insert_blog_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-blog-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20250923: created delete_blog_demo_data() to run Perl script that deletes blog demo data
sub delete_blog_demo_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'delete-blog-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 2021010: created verify_blog_cleanup() to run Perl script that verifies deletion of blog demo data
sub verify_blog_cleanup() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'verify-blog-cleanup');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20251017: run program that inserts pages demo data
sub insert_pages_demo_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-pages-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20251017: run program that inserts news demo data
sub insert_news_demo_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-news-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 20251017: run program that deletes news demo data
sub delete_news_demo_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'delete-news-demo-data');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

# KBAKER 2021010: run program that verifies deletion of news demo data
sub verify_news_cleanup() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'verify-news-cleanup');

    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}