use warnings;
use strict;
use utf8;

=head1 NAME

RTPG::WWW::Frame::Status

=cut

package RTPG::WWW::Frame::Status;
use RTPG;
use RTPG::WWW::Config;

=head2 new

Get params

=cut

sub new
{
    my ($class, %opts) = @_;

    # Get current state
    $opts{$_} = cfg->get($_) for qw(download_rate upload_rate);

    # Get RTPG object
    my $rtpg = RTPG->new(url => cfg->get('rpc_uri'));

    # Do commands
    $rtpg->set_download_rate($opts{download_rate})
        if $opts{download_rate} =~ m/^\d+$/;
    $rtpg->set_upload_rate($opts{upload_rate})
        if $opts{upload_rate} =~ m/^\d+$/;

    my $error;
    # Get information about system
    ($opts{info}, $error) = $rtpg->system_information;
    $opts{error} ||= $error;

    # Get information about rates
    ($opts{rates}, $error) = $rtpg->rates;
    $opts{error} ||= $error;

    # Sum current rates
    ($opts{list}, $error) = $rtpg->torrents_list;
    $opts{error} ||= $error;
    $opts{rates}{current_upload_rate} = 0;
    $opts{rates}{current_download_rate} = 0;
    map {
        $opts{rates}{current_upload_rate}   += $_->{up_rate};
        $opts{rates}{current_download_rate} += $_->{down_rate};
    } @{ $opts{list} };

    my $self = bless \%opts, $class;

    return $self;
}

1;
