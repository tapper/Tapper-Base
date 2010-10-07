package Artemis::Base;


use Moose;
use Fcntl;
use LockFile::Simple;

use common::sense;


use 5.010;

with 'MooseX::Log::Log4perl';


=head1 NAME

Artemis::Base - Common functions for all Artemis classes

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.010018';


=head1 SYNOPSIS

Currently, only an OO interface is implemented. Non-OO will follow when needed.

 use Artemis::Base;
 use Moose;

 extends 'Artemis::Base';


=head1 FUNCTIONS

=head2 kill_instance

Kill the process whose id is in the given pidfile.

@param string - pid file name

@return success - 0
@return error   - error string

=cut

sub kill_instance
{
        my ($self, $pid_file) = @_;

        # try to kill previous incarnations
        if ((-e $pid_file) and open(my $fh, "<", $pid_file)) {{
                my $pid = do {local $\; <$fh>}; # slurp
                ($pid) = $pid =~ m/(\d+)/;
                last unless $pid;
                kill 15, $pid;
                sleep(2);
                kill 9, $pid;
                close $fh;
        }}
        return 0;

}

=head2 run_one

Run one instance of the given command. Kill previous incarnations if necessary.

@param hash ref - {command  => command to execute,
                   pid_file => pid file containing the ID of last incarnation,
                   argv     => array ref containg (optional) arguments}


@return success - 0
@return error   - error string

=cut

sub run_one
{
        my ($self, $conf) = @_;

        my $command  = $conf->{command};
        my $pid_file = $conf->{pid_file};
        my @argv     = @{$conf->{argv} // [] } ;

        $self->kill_instance($pid_file);

        return qq(Can not execute "$command" because it's not an executable) unless -x $command;
        my $pid = fork();
        return qq(Can not execute "$command". Fork failed: $!) unless defined $pid;

        if ($pid == 0) {
                exec $command, @argv;
                exit 0;
        }

        return 0 unless $pid_file;
        open(my $fh, ">", $pid_file) or return qq(Can not open "$pid_file" for pid $pid:$!);
        print $fh $pid;
        close $fh;
        return 0;
}



=head2 makedir

Checks whether a given directory exists and creates it if not.

@param string - directory to create

@return success - 0
@return error   - error string

=cut

sub makedir
{
        my ($self, $dir) = @_;
        return 0 if -d $dir;
        if (-e $dir and not -d $dir) {
                unlink $dir;
        }
        system("mkdir","-p",$dir) == 0 or return "Can't create $dir:$!";
        return 0;
}


=cut

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
        my ($self, $filename, $content) = @_;
        my $error = 0;
        my $tmp_fh;
        while (sysopen($tmp_fh, $filename.".lock", O_EXCL)) {
                sleep 1;
        }
        {
                open(my $fh, ">", $filename) or $error = "Can't open $filename: $!",last;
                print $fh $content or $error = "Can't write to $filename: $!",close $fh, last;
                close $fh or $error = "Can't open $filename: $!",last;
        }
        close $tmp_fh;
        unlink "$filename.lock";
        return $error;
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
        my ($self, $filename) = @_;
        my ($content, $tmp_fh);
        while (sysopen($tmp_fh, $filename.".lock", O_CREAT | O_EXCL) != 0) {
                sleep 1;
        }
        {
                open(my $fh, "<", $filename) or last;
                local $\;
                $content = <$fh>;
                close $fh or $content = undef, last;
        }
        close $tmp_fh;
        unlink "$filename.lock";
        return $content;
}


=head2 atomic_decrement

Decrement the value in the given file, return the decremented value.

@return success                - ( 0, int)    - decremented value
@return locked and nonblocking - (-1, undef)  - error string
@return error                  - ( 1, string) - error string

=cut

sub atomic_decrement
{
        my ($self, $filename, $blocking) = @_;
        my ($content, $tmp_fh);
        my $lockmgr = LockFile::Simple->make(-format => '%f.lck', -nfs => 1, stale => 1, autoclean => 1);

        if ($blocking) {
                $lockmgr->lock($filename) or return (1, "Can not lock $filename: $!");
        } else {
                $lockmgr->trylock($filename) or return (-1, undef);
        }

        {
                open(my $fh, "<", $filename) or last;
                local $\;
                $content = <$fh>;
                chomp $content;
                close $fh;
        }

        return (1, "File does not contain only a number") if not $content =~/^\d+$/;
        $content--;
        {
                open(my $fh, ">", $filename) or last;
                local $\;
                print $fh ($content);
                close $fh;
        }
        $lockmgr->unlock($filename);
        return (0, $content);
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
