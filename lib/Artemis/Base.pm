package Artemis::Base;

use warnings;
use strict;

use Moose;

with 'MooseX::Log::Log4perl';


=head1 NAME

Artemis::Base - Common functions for all Artemis classes

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.010002';


=head1 SYNOPSIS

Currently, only an OO interface is implemented. Non-OO will follow when needed.

 use Artemis::Base;
 use Moose;

 extends 'Artemis::Base';


=head1 FUNCTIONS


=head2 log_and_exec

Execute a given command. Make sure the command is logged if requested and none
of its output pollutes the console. In scalar context the function returns 0
for success and the output of the command on error. In array context the
function always return a list containing the return value of the command and
the output of the command.

@param string - command

@return success - 0
@return error   - error string
@returnlist success - (0, output)
@returnlist error   - (return value of command, output)

=cut

sub log_and_exec
{
        my ($self, @cmd) = @_;
        my $cmd = join " ",@cmd;
        $self->log->debug( $cmd );
        my $output=`$cmd 2>&1`;
        my $retval=$?;
        if (not defined($output)) {
                $output = "Executing $cmd failed";
                $retval = 1;
        }
        chomp $output if $output;
        if ($retval) {
                return ($retval >> 8, $output) if wantarray;
                return $output;
        }
        return (0, $output) if wantarray;
        return 0;
}


=head2 atomic_write

Writes given content to a given file and handles multiple access to this file
correctly. In case content can not be written immediately it blocks until
writing is possible. Starvation is not prevented.
Note: does not protect against clashes with nonatomic writes.

@param string - file name
@param string - file content

@param success - 0
@param error   - error string

=cut

sub atomic_write
{
        my ($filename, $content) = @_;
        my $error = 0;
        while (sysopen(my $tmp , $filename.".lock", O_EXCL) != 0) {
                sleep 1;
        }
        {
                open(my $fh, ">", $filename) or $error = "Can't open $filename: $!",last;
                print $fh $content or $error = "Can't write to $filename: $!",close $fh, last;
                close $fh or $error = "Can't open $filename: $!",last;
        }
        close $tmp;
        unlink "$filename.lock";
}

=head2 atomic_read

Reads content from a file if and only if noone is currently writing this
file. Find error in $! if reading does not succeed. 
Note: does not protect against clashes with nonatomic writes.

@param string - file name

@param success - content (string)
@param error   - undef (see $!)

=cut

sub atomic_read
{
        my ($filename) = @_;
        my $error = 0;
        while (sysopen(my $tmp , $filename.".lock", O_EXCL) != 0) {
                sleep 1;
        }
        {
                open(my $fh, "<", $filename) or $error = "Can't open $filename: $!",last;
                local $\;
                $content = <$fh>;
                close $fh or $error = "Can't open $filename: $!",last;
        }
        close $tmp;
        unlink "$filename.lock";
}



=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-artemis-base at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Artemis-Base>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Artemis::Base
