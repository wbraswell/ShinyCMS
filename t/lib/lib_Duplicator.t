# ===================================================================
# File:		  t/lib/lib_Duplicator.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS::Duplicator
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2021 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'ShinyCMS::Model::DB'  }
BEGIN { use_ok 'ShinyCMS::Schema'     }
BEGIN { use_ok 'ShinyCMS::Duplicator' }

use lib 't/support';
require 'helpers.pl';  ## no critic

my $from_db = get_schema();
my $to_db   = get_schema();

my $duplicator = ShinyCMS::Duplicator->new({
	source_db      => $from_db,
	destination_db => $to_db
});

ok(
  defined $duplicator,
  'Created a ShinyCMS::Duplicator'
);
ok(
  ( not $duplicator->result ),
  'ShinyCMS::Duplicator has no result to report yet.'
);
ok(
  $duplicator->not_ready_to_clone,
  'ShinyCMS::Duplicator is not ready to clone.'
);
ok(
  ( not $duplicator->clone->cloned_item ),
  'Calling ->clone does not work.'
);
ok(
  $duplicator->has_errors,
  'ShinyCMS::Duplicator has errors.'
);
ok(
  $duplicator->error_message =~ /Source item not specified/,
  'ShinyCMS::Duplicator error message includes "Source item not specified".'
);
ok(
  ( not defined $duplicator->success_message ),
  'ShinyCMS::Duplicator success message is blank while there are errors.'
);
ok(
  $duplicator->result eq $duplicator->error_message,
  'ShinyCMS::Duplicator->result now returns the error message.'
);
ok(
  ( not $duplicator->is_supported_type( 'TestFail' ) ),
  'TestFail is not a supported item type.'
);
ok(
  $duplicator->is_supported_type( 'CmsPage' ),
  'CmsPage is a supported item type.'
);
ok(
  $duplicator->set_source_item( 'CmsTemplate', 99999 ),
  "Setting source item that doesn't exist"
);
ok(
  $duplicator->error_message =~ /CmsTemplate #99999 not found/,
  'ShinyCMS::Duplicator error message includes "CmsTemplate #9999 not found".'
);

my $source_id = $from_db->resultset( 'CmsPage' )->first->id;

ok(
  $duplicator->set_source_item( 'CmsPage', $source_id ),
  'Setting source item that does exist'
);
ok(
  $duplicator->ready_to_clone,
  'ShinyCMS::Duplicator is ready to clone'
);
ok(
  ( not $duplicator->has_errors ),
  'ShinyCMS::Duplicator does not have errors.'
);
ok(
  $duplicator->clone,
  'Cloning!'
);
ok(
  ( not $duplicator->has_errors ),
  'ShinyCMS::Duplicator does not have errors.'
);
ok(
  ( not defined $duplicator->error_message ),
  'ShinyCMS::Duplicator error message is blank now that there are no errors.'
);
ok(
  $duplicator->success_message =~ /Duplicator cloned a CmsPage/,
  'ShinyCMS::Duplicator success message includes "Duplicator cloned a CmsPage".'
);
ok(
  $duplicator->result eq $duplicator->success_message,
  'ShinyCMS::Duplicator->result returns the success message.'
);

$duplicator->cloned_item->elements->delete_all;
$duplicator->cloned_item->delete;

my $data1 = { url_test => 'ShinyCMS' };
my $data2 = { url_name => 'ShinyCMS' };
my $data3 = { url_name => 'ShinyCMS-clone'   };
my $data4 = { url_name => 'ShinyCMS-clone-8' };

ok(
  ShinyCMS::Duplicator::update_url_name( $data1 )->{ url_test } eq 'ShinyCMS',
  'update_url_name does not affect a hash without that key'
);
ok(
  ShinyCMS::Duplicator::update_url_name( $data2 )->{ url_name } eq 'ShinyCMS-clone',
  'update_url_name adds -clone to a normal url_name value'
);
ok(
  ShinyCMS::Duplicator::update_url_name( $data3 )->{ url_name } eq 'ShinyCMS-clone-2',
  'If a url_name already ends in -clone, update_url_name adds -2 to it'
);
ok(
  ShinyCMS::Duplicator::update_url_name( $data4 )->{ url_name } eq 'ShinyCMS-clone-9',
  'If a url_name ends in -clone-N, update_url_name increments N'
);

ok(
  ShinyCMS::Duplicator::parent_id_column( ShinyCMS::Schema::Result::CmsPageElement->new ) eq 'page',
  "A CMS Page Element has the parent_id_column 'page'"
);
ok(
  ShinyCMS::Duplicator::parent_id_column( ShinyCMS::Schema::Result::CmsTemplateElement->new ) eq 'template',
  "A CMS Template Element has the parent_id_column 'template'"
);
ok(
  ShinyCMS::Duplicator::parent_id_column( ShinyCMS::Schema::Result::ShopItemElement->new ) eq 'item',
  "A Shop Item Element has the parent_id_column 'item'"
);
ok(
  ShinyCMS::Duplicator::parent_id_column( ShinyCMS::Schema::Result::ShopProductTypeElement->new ) eq 'product_type',
  "A Shop Product Type Element has the parent_id_column 'product_type'"
);

# Test bad things
throws_ok
  { ShinyCMS::Duplicator::parent_id_column( ShinyCMS::Schema::Result::SharedContent->new ) }
  qr/Failed to identify parent entity for SharedContent/,
  "parent_id_column dies with an appropriate warning if fed a type it can't handle";

throws_ok
  { $duplicator->set_source_item() }
  qr/set_source_item requires item_type and item_id/,
  'set_source_item fails with an appropriate warning when not given item_id and item_type';

throws_ok
  { $duplicator->set_source_item( 'TEST', 0 ) }
  qr/set_source_item requires item_type and item_id/,
  'set_source_item fails with an appropriate warning when not given item_id and item_type';

done_testing();
