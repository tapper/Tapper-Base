use inc::Module::Install;

name     'Tapper-Action';
all_from 'lib/Tapper/Action.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

build_requires 'Test::More';

requires 'YAML::Syck' => 0;
requires 'Tapper::Base';
requires 'Tapper::Config' => '3.000011';
requires 'App::Daemon';
requires 'Log::Log4perl';
auto_install;

WriteAll;

