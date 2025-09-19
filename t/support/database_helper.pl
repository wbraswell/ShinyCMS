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