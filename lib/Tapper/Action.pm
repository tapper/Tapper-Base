package Tapper::Action;

use 5.010;
use warnings;
use strict;

use Moose;
use Tapper::Model 'model';
use YAML::Syck 'Load';
use Tapper::Config;
use Log::Log4perl;
extends 'Tapper::Base';

has cfg => (is => 'rw', default => sub { Tapper::Config->subconfig} );

=head1 NAME

Tapper::Action - Execute actions on request.

=head1 VERSION

Version 1.000001

=cut

our $VERSION = '1.000001';


=head1 SYNOPSIS

There are a few actions that Tapper assigns to an external daemon. This
includes for example restarting a test machine that went to sleep during
ACPI tests. This module is the base for a daemon that executes these
assignments.

    use Tapper::Action;

    my $daemon = Tapper::Action->new();
    $daemon->run();


=head1 FUNCTIONS

=head2 get_messages

Read all pending messages from database. Try no more than timeout seconds

@return success - Resultset class countaining all available messages

=cut

sub get_messages
{
        my ($self) = @_;

        my $messages;
        while () {
                $messages = model('TestrunDB')->resultset('Message')->search({type => 'action'});
                last if ($messages and $messages->count);
                sleep $self->cfg->{times}{action_poll_intervall} || 1;
        }
        return $messages;
}

=head2 resume

Handle the resume message.

@param hash ref - message 

=cut

sub resume 
{                                        
        my ($self, $message) = @_;
        $SIG{CHLD} = 'IGNORE';
        my $pid = fork();
        
        $self->log->error("Can not fork: $!") if not defined $pid;
        if ($pid == 0) {
                my $host = $message->{host};
                sleep( $message->{after} || $self->cfg->{action}{resume_default_sleeptime} || 0);
                my $cmd  = $self->cfg->{actions}{resume};
                $cmd    .= " $host";
                my ($error, $retval) = $self->log_and_exec($cmd);
                exit 0;
        }
        return;
}


=head2 run

Run the Action daemon loop.


=cut

sub run
{
        my ($self) = @_;
        Log::Log4perl->init($self->cfg->{files}{log4perl_cfg});


 ACTION:
        while (my $messages = $self->get_messages) {
                while (my $message = $messages->next) {
                        given($message->message->{action}){
                                when ('reset')  {
                                        $self->log->error("reset is not yet implemented")
                                }
                                when ('resume') {
                                        $self->resume($message->message);
                                }
                                default         {
                                        $self->log->error('Unknown action "'.$message->message->{action}.'"')
                                }
                        }
                        $message->delete;
                }
        }
        return;
}

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tapper-action at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-Action>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tapper::Action


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tapper-Action>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tapper-Action>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tapper-Action>

=item * Search CPAN

L<http://search.cpan.org/dist/Tapper-Action/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tapper::Action
