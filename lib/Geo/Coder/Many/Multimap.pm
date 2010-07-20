package Geo::Coder::Many::Multimap;

use strict;
use warnings;

use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Multimap

=head1 SYNOPSIS

This class wraps Geo::Coder::Multimap such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Multimap, and returns the
result in a form understandable to Geo::Coder::Many

=cut

sub geocode {
    my ($self, $location) = @_;

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    for my $raw_reply (@raw_replies) {
        my $tmp = {
            address     => $raw_reply->{address}->{display_name},
            longitude   => $raw_reply->{point}->{lon},
            latitude    => $raw_reply->{point}->{lat},
            precision   => undef, # May be set below
        };

        # We want to convert the geocode_quality value into a 'precision' score.
        # Multimap also provides an undocumented 'geocode_score' value, but it
        # doesn't seem to be helpful.
        #
        # See http://clients.multimap.com/share/documentation/general/gqcodes.htm
        # for a detailed specification of the geocode_quality value - we don't use
        # all of the information it provides, here.

        if ( defined $raw_reply->{geocode_quality} ) {

            my %quality_hash = (
                qr/NULL/i      => 0.0,
                qr/0/          => 0.0,
                qr/1.*/        => 0.9,     # ~ House number
                qr/2.*/        => 0.75,    # ~ Street
                qr/3.*/        => 0.4,     # ~ Town
                qr/4.*/        => 0.4,     # ~ Postal code
                qr/5.*/        => 0.3,     # ~ State
                qr/6(a|ax)?.*/ => 0.6,     # Town and postal code
                qr/6n/         => 0.1,     # Country (geocodes to capital...)
                qr/z5/         => 0.4,     # Five-digit US ZIP code
                qr/z7/         => 0.6,     # US 'ZIP+2' code
                qr/z9/         => 0.8,     # US 'ZIP+4' code
                qr/7.*/        => undef,
                qr/8.*/        => undef,
                qr/9.*/        => undef,
            );

            while (my ($code_regex, $precision) = each %quality_hash) {
                if ($raw_reply->{geocode_quality} =~ /^\s*$code_regex\s*/) {
                    $tmp->{precision} = $precision;
                }
            }
        }

        $response->add_response( $tmp, $self->get_name() );
    }

    return( $response );
};

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { return 'multimap' };


1;

__END__
