use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-Base';
all_from 'lib/Tapper/Base.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

build_requires 'Test::More';
build_requires 'Test::Perl::Critic';

author_requires 'Module::Install::WriteAll';

requires 'common::sense';
requires 'Fcntl';
requires 'LockFile::Simple';
requires 'MooseX::Log::Log4perl';

auto_install;

WriteAll;

