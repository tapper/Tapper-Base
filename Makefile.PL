use inc::Module::Install;

name     'Tapper-Base';
all_from 'lib/Tapper/Base.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

build_requires 'Test::More';
build_requires 'Test::Perl::Critic';

requires 'common::sense';
requires 'Fcntl';
requires 'LockFile::Simple';
requires 'MooseX::Log::Log4perl';

auto_install;

WriteAll;

