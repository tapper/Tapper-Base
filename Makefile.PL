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
setup_deploy;

WriteAll;

