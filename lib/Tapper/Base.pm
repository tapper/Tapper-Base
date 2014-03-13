package Tapper::Base;
# ABSTRACT: Tapper - Common functions for all Tapper classes

use Moose;

use common::sense;

use 5.010;

with 'MooseX::Log::Log4perl';

=head1 SYNOPSIS

 package Tapper::Some::Class;
 use Moose;
 extends 'Tapper::Base';

=head1 FUNCTIONS

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

1; # End of Tapper::Base
