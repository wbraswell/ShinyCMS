package ShinyCMS::Model::FilterHTML;

use Moose;
use namespace::clean -except => 'meta';

extends qw/ Catalyst::Model /;


use HTML::Restrict;


=head1 NAME

ShinyCMS::Model::FilterHTML

=head1 DESCRIPTION

HTML-filtering model class for ShinyCMS

=cut


=head1 METHODS

=head2 filter

=cut

sub filter {
	my( $self, $html, $type ) = @_;

	# TODO: Fetch list of allowed tags and attributes from config
	# TODO: Use $type to pick an allowed-tag list, otherwise use the default

	my $rules = {
		b      => [],
		strong => [],
		i      => [],
		em     => [],
		small  => [],
		p      => [],
		br     => [ qw ( / ) ],
		a      => [ qw( href title ) ],
#		img    => [ qw( src alt title width height / ) ]
	};

	# Create a HTML::Restrict object
	my $hr = HTML::Restrict->new;

	# Feed in the list of allowed tags and attributes
	$hr->set_rules( $rules );

	# Pass the HTML through it
	my $filtered = $hr->process( $html );

	# Return the filtered HTML
	return $filtered;
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
