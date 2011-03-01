package Tapper::Base;


use Moose;
use Fcntl;
use LockFile::Simple;

use common::sense;


use 5.010;

with 'MooseX::Log::Log4perl';


=head1 NAME

Tapper::Base - Common functions for all Tapper classes

=cut

our $VERSION = '3.000001';

=head1 SYNOPSIS

Currently, only an OO interface is implemented. Non-OO will follow when needed.

 use Tapper::Base;
 use Moose;

 extends 'Tapper::Base';


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


=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tapper-base at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-Base>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=cut

1; # End of Tapper::Base
