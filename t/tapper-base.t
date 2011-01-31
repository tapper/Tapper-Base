#!/usr/bin/env perl

use warnings;
use strict;
use Log::Log4perl;
use File::Temp;

my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


use Test::More;

package Foo::Test;
use Moose;

use Tapper::Base;
extends 'Tapper::Base';

# want to test OO interface thus we need a separate class since Moose doesn't
# offer it's tricks to main
sub test_log_and_exec
{
        my ($self, @cmd) = @_;
        return $self->log_and_exec(@cmd);
}

package main;

my $test   = Foo::Test->new();
my $retval = $test->test_log_and_exec('/bin/true');
is($retval, 0, 'Log_and_exec in scalar context');

my $ft = File::Temp->new();
my $filename = $ft->filename;

$test = Tapper::Base->new();

local $SIG{CHLD} = 'IGNORE';

$retval = $test->run_one({command  => "t/misc_files/sleep.sh",
                          pid_file => $filename,
                          argv     => [ 100 ]});
is($retval, 0, 'Run_one sleep without error');

$retval = $test->run_one({command => "t/misc_files/sleep.sh",
                          pid_file => $filename,
                          argv    => [ 1 ]});
is($retval, 0, 'Run_one second sleep without error');


done_testing();
