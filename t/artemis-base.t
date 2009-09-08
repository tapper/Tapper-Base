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


use Test::More tests => 2;

package Foo::Test;
use Moose;

use Artemis::Base;
extends 'Artemis::Base';

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
my $content = "first line\nsecond line\n\tthird line\n";

$retval = $test->atomic_write($filename, $content);
is($retval, 0, 'Atomic write');
