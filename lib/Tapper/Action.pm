package Tapper::Action;

use 5.010;
use warnings;
use strict;

use Moose;
use Tapper::Model 'model';
use Tapper::Config;
use YAML::Syck 'Load';
use Log::Log4perl;

extends 'Tapper::Base';

has cfg => (is => 'rw', default => sub { Tapper::Config->subconfig} );

our $VERSION = '3.000011';

=head1 NAME

Tapper::Action - Tapper - Daemon and plugins to handle MCP actions

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

@return success - Resultset class containing all available messages

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
                        if (my $action = $message->message->{action}) {
                                my $plugin         = $self->cfg->{action}{$action}{plugin};
                                my $plugin_options = $self->cfg->{action}{$action}{plugin_options};
                                my $plugin_class   = "Tapper::Action::Plugin::${action}::${plugin}";
                                eval "use $plugin_class"; ## no critic

                                if ($@) {
                                        return "Could not load $plugin_class";
                                } else {
                                        no strict 'refs'; ## no critic
                                        $self->log->info("Call ${plugin_class}::execute()");
                                        my ($error, $retval) = &{"${plugin_class}::execute"}($self, $message->message, $plugin_options);
                                        $self->log->error("Error occured: ".$retval) if $error;
                                }
                        }
                        $message->delete;
                }
        }
        return;
}

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

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

Copyright 2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd


=cut

1; # End of Tapper::Action
