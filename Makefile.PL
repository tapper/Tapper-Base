use inc::Module::Install;

name     'Artemis-Base';
all_from 'lib/Artemis/Base.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

build_requires 'Test::More';

requires 'Fcntl';
requires 'LockFile::Simple';
requires 'MooseX::Log::Log4perl';

auto_install;

postamble("

live:
\t./scripts/dist_upload_wotan.sh
\tssh artemis\@bancroft \"/opt/artemis/bin/cpan Artemis::BaseCLI\"

devel: install
");

WriteAll;

