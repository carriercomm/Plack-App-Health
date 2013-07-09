package Plack::App::Health;
#ABSTRACT: report system health
use strict;
use warnings;
use parent 'Plack::Component';

use Plack::Util::Accessor qw(services components);

use JSON 'to_json';

sub call {
    my ($self, $env) = @_;

    my %report;

    for my $type ('services', 'components') {
        my @elements;

        for my $element (@{ $self->$type || [] }) {
            my %rendered = %$element;

            # any coderefs should be executed to produce their value
            for my $key (keys %rendered) {
                if (ref($rendered{$key}) eq 'CODE') {
                    $rendered{$key} = $rendered{$key}->($self, $element);
                }
            }

            push @elements, \%rendered;
        }

        $report{$type} = \@elements;
    }

    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ to_json(\%report) ]
    ];
}

1;

__END__

=head1 SYNOPSIS

    mount '/status' => 'Plack::App::Health' => (
        components => [
            { name => 'Perl', version => $] },
            { name => 'Plack', version => $Plack::VERSION },
        ],
        services => [
            {
                name => 'PostgreSQL',
                type => 'Database',
                status => sub {
                    my $dbh = ...;
                    return $dbh->ping ? "Up" : "Down";
                },
            },
            {
                name => 'Web Services',
                type => 'Backend API',
                status => sub {
                    my $lwp = LWP::UserAgent->new;
                    return $lwp->get(...)->is_success ? "Up" : "Down";
                }
            },
        ],
    );

=head1 DESCRIPTION

=cut


