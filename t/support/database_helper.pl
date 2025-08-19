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

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..', '..'));

sub insert_forum_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-forums-demo-data');
    
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}

sub insert_required_data() {
    my $target_script = File::Spec->catfile($repo_root, 'bin', 'database', 'data', 'insert-required-data');
    
    system($^X, $target_script) == 0
        or die "Failed to run $target_script: $?";
}