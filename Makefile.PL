use inc::Module::Install;

name     'Tapper-Action';
all_from 'lib/Tapper/Action.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

