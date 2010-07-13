use warnings;
use strict;
use utf8;

=head1 NAME

RTPG::WWW::Config configuration module.

=cut

package RTPG::WWW::Config;
use base qw(Exporter);

use CGI::Simple;
# Set CGI file upload parameters
$CGI::Simple::POST_MAX = 1024000;
$CGI::Simple::DISABLE_UPLOADS = 0;

use File::Basename;
use File::Spec;

our @EXPORT = qw(cfg DieDumper Dumper);

################################################################################
# This section contains some paths for use in this program
# Edit this for some OS
# I think no any place to change. If it`s wrong, please inform me.
# (Except config file)
################################################################################
use constant RTPG_SYSTEM_CONFIG_PATH  => '/etc/rtpg/rtpg.conf';
use constant RTPG_CONFIG_PATH         => '~/.rtpg/rtpg.conf';
################################################################################

=head2 cfg

Get cached config object

=cut

sub cfg
{
    our $config;

    # Cache config
    return $config if $config;
    $config = RTPG::WWW::Config->new;
    return $config;
}

sub new
{
    my $class = shift;
    my %opts;

    $opts{dir}{config} = [
        RTPG_SYSTEM_CONFIG_PATH,
        RTPG_CONFIG_PATH,
    ];
    # Redefining config path from server options.
    $opts{dir}{config} = [ $ENV{RTPG_CONFIG} ] if $ENV{RTPG_CONFIG};

    $opts{title} = "RTPG";

    $opts{dir}{base} = File::Spec->rel2abs( dirname(__FILE__) . '/../../..' );
    # Make clean basedir
    while( $opts{dir}{base} =~ s{(?:/[^\./]+/\.\.)}{}g ) {;}

    # Other dirs
    $opts{dir}{templates}   = $opts{dir}{base}      . '/templates';
    $opts{dir}{po}          = $opts{dir}{base}      . '/po';

    # Absolute resources dirs
    $opts{dir}{htdocs}      = $opts{dir}{base}      . '/htdocs';
    $opts{dir}{css}         = $opts{dir}{htdocs}    . '/css';
    $opts{dir}{img}         = $opts{dir}{htdocs}    . '/img';
    $opts{dir}{js}          = $opts{dir}{htdocs}    . '/js';

    # Relative resource urls
    $opts{url}{base}        = $ENV{SCRIPT_NAME};
    $opts{url}{base}        =~ s{/[^/]*$}{/};
    $opts{url}{base}        = $ENV{SERVER_NAME} . $opts{url}{base};

    my $self = bless \%opts, $class;

    $self->{'_cgi'} = new CGI::Simple;

    my ($browser_locale) = $ENV{HTTP_ACCEPT_LANGUAGE} =~ m/^(\w+)/;

    # Set parameters by default, even it not declared in config file
    $self->set('action',     'default' ) unless $self->get('action');
    $self->set('locale',     $self->get('locale') || $browser_locale || 'en' );
    $self->set('horizontal', '190,*' )   unless $self->get('horizontal');
    $self->set('vertical',   '*,300' )   unless $self->get('vertical');

    # Load params from file
    $self->load_from_files;

    # Get skin files path
    $self->{dir}{skin}{files}   = $opts{dir}{htdocs} . '/skins';

    # Get current skin and check for skin available
    my $skin = $self->get('skin');
    unless( $self->get('skin') ~~ @{[ keys %{$self->skins} ]} )
    {
        $skin = 'default';
        $self->set('skin', $skin);
    }

    # Get over skin files path
    $self->{dir}{skin}{current} = $self->{dir}{skin}{files} . '/' . $skin;
    $self->{dir}{skin}{base}    = $self->{dir}{templates}   . '/' . $skin;
    $self->{dir}{skin}{default} = $self->{dir}{templates}   . '/default';
    # Get over skin files url
    $self->{url}{skin}{current}    = 'skins/' . $skin;
    $self->{url}{skin}{default} = 'skins/default';
    $self->{url}{skin}{panel}   = $self->{url}{skin}{current} . '/panel';
    $self->{url}{skin}{status}  = $self->{url}{skin}{current} . '/status';
    $self->{url}{skin}{mime}    = $self->{url}{skin}{current} . '/mimetypes';

    # Init parameters from current value to cookie
    # It`s need for first time start to init all default cookie
    $self->set($_, $self->get($_)) for qw(refresh skin layout);

    return $self;
}

sub load_from_files
{
    my ($self) = @_;

    # Set default params
    $self->{param} = {};

    # Flag successful loaded
    my $loaded = 'no';

    # Loading: first default config, next over users config
    for my $config ( @{$self->{dir}{config}} )
    {
        # Get abcoulete path
        ($config) = glob $config;

        # Next if file not exists
        next unless -f $config;

        # Open config file
        open my $file, '<', $config
            or warn sprintf('Can`t read config file %s : %s', $config, $!);
        next unless $file;

        # Read and parse file. Next hash write over previus configuration hash
        %{ $self->{param} } = (
            %{ $self->{param} },
            (
                map{ split m/\s*=\s*/, $_, 2 }
                grep m/=/,
                map { s/#\s.*//; s/^\s*#.*//; s/\s+$//; s/^\s+//; $_ } <$file>
            )
        );

        # Close file and mark successful loaded
        close $file;
        $loaded = 'yes';
    }

    # Exit if no one config exists
    die 'Config file not exists' unless $loaded eq 'yes';

    # Replace by old parameters from RTPG 0.1.x version
    if( exists $self->{param}{refresh_timeout} )
    {
        $self->{param}{refresh} = $self->{param}{refresh_timeout};
        delete $self->{param}{refresh_timeout};
    }
    if( exists $self->{param}{current_skin} )
    {
        $self->{param}{skin} = $self->{param}{current_skin};
        delete $self->{param}{current_skin};
    }

    return 1;
}

=head2 cgi

returns CGI object

=cut

sub cgi
{
    my ($self) = @_;
    return $self->{'_cgi'};
}


=head2 get $name

Get parameter by $name.

=cut

sub get
{
    my ($self, $name) = @_;
    return ($self->cgi->param($name))
        if defined $self->cgi->param($name)     and wantarray;
    return ($self->cgi->cookie($name))
        if defined $self->cgi->cookie($name)    and wantarray;
    return ($self->{param}{$name})
        if defined $self->{param}{$name} and wantarray;

    return $self->cgi->param($name)     // $self->cgi->cookie($name) //
           $self->{param}{$name} // '';
}

=head2 upload $name

Get uploaded file handle

=cut

sub upload
{
    my ($self, $name) = @_;
    return $self->cgi->upload($name);
}


=head2 upload_mime_type $name

Get uploaded file mime info

=cut

sub upload_mime_type
{
    my ($self, $name) = @_;
    return $self->cgi->upload_info($self->cgi->param($name), 'mime');
}


=head2 set $name, $value

Set new $value for parameter by $name.

=cut

sub set
{
    my ($self, $name, $value) = @_;

    # Permanent set new state into cookies
    push @{ $self->{cookies} },
        $self->cgi->cookie(-name => $name, -value => $value, -expires => '+2y')
            unless $value eq $self->cgi->cookie($name);

    $self->{param}{$name} = $value;
}

=head2 cookies

Get cookies to response

=cut

sub cookies { return shift->{cookies}; }

=head2 skins

Get list of available skins

=cut

sub skins
{
    my ($self) = @_;

    # Cache
    return $self->{skins} if $self->{skins};

    # Get paths to skins
    my @paths = glob sprintf( '%s/*', $self->{dir}{skin}{files});

    # Get skins titles
    my %skins;
    for my $path ( @paths )
    {
        # Get name as last part of path
        my ($name) = $path =~ m|^.*/(.*?)$|;
        # Set fullpath
        my $file = sprintf '%s/%s/title.txt', $self->{dir}{skin}{files}, $name;
        # Get title from file if file accessible
        my $title;
        if( -f $file and -r _ and -s _ )
        {
            $title = `cat $file`;
            s/^\s+//, s/\s+$//, s/[^\w\s.,)(]//g for $title;
        }
        # Set skin description
        $skins{$name} = $title || ucfirst( lc $name );
    }

    $self->{skins} = \%skins;
    return $self->{skins};
}

=head2 is_collapse

Return true if html collapse enabled

=cut

sub is_collapse
{
    return ( shift->get('collapse') =~ m/^(yes|on|enable)$/i) ?1 :0;
}

=head2 is_geo_ip

Return true if geo_ip enabled

=cut
sub is_geo_ip
{
    return ( shift->get('geo_ip') =~ m/^(yes|on|enable)$/i) ?1 :0;
}

=head2 DieDumper

Print all params and die

=cut

sub DieDumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);
    $dump=~s/(\\x\{[\da-fA-F]+\})/eval "qq{$1}"/eg;
    die $dump;
}

=head2 Dumper

Get all params description

=cut

sub Dumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);

    return $dump;
}

1;

=head1 AUTHORS

Copyright (C) 2008 Dmitry E. Oboukhov <unera@debian.org>,

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
