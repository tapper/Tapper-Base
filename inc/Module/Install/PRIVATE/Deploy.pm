package Module::Install::PRIVATE::Deploy;

use strict;
use warnings;
use Module::Install::Base;
use Data::Dumper;


our $VERSION = '0.010000';
use base qw{ Module::Install::Base };

sub setup_deploy {
	my $self  = shift;
        my ($tmp) = grep {ref $_ eq 'Module::Install::Metadata'} @{$self->_top->{extensions}};
        


	$self->postamble("
# --- Deploy section:

SOURCE_DIR=/home/artemis/perl510/lib/site_perl/5.10.0/
DEST_DIR=/opt/artemis/lib/perl5/site_perl/5.10.0/


live:
\t./scripts/dist_upload_wotan.sh
\tssh artemis\@bancroft \"sudo rsync -ruv  \${SOURCE_DIR}/\${FULLEXT}.pm \${DEST_DIR}/\${}; sudo rsync -ruv  \${SOURCE_DIR}/MCP/ \${DEST_DIR}/MCP/\"
\tssh artemis\@bancroft \"sudo rsync -ruv  /home/artemis/perl510/bin/artemis-mcp* /opt/artemis/bin/\"
devel: install
");
}
