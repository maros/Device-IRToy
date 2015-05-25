#!/usr/bin/env perl

use strict;
use 5.016;
use lib qw(lib/);

use Device::IRToy;

my %COMMANDS = (
    sleep       => { code => 312,  module => 6, },
    power       => { code => 40,   module => 6 },
    vol_up      => { code => 712,  module => 6 },
    vol_down    => { code => 200,  module => 6 },
    toggle      => { code => 1000, module => 6 },
    1           => { code => 264,  module => 6 },
    10          => { code => 152,  module => 6 },
    cd_play     => { code => 232,  module => 2 },
);

my $ir = Device::IRToy->new( port => '/dev/ttyACM0' );
$ir->sampling_mode();

sub _transmit {
    my (%params) = @_;
    if (my $command = delete $params{command}) {
        foreach my $key (keys %{$COMMANDS{$command}}) {
            $params{$key} //= $COMMANDS{$command}->{$key};
        } 
    }
    $params{count} //= 1;
    $params{length} //= 10;
    $ir->transmit_protocol(
        'Denon',
        \%params,
    );
}

sub action_off {
    _transmit(command => '10');
    _transmit(command => 'power');
}

sub action_on {
    _transmit(command => 'sleep');
    sleep(10);
    _transmit(command => 'sleep', count => 6);
}

sub action_aux {
    _transmit(command => '10');
    _transmit(command => 'toggle');
    _transmit(command => 'toggle');
}

sub action_vol_up {
    _transmit(command => 'vol_up');
}

sub action_vol_down {
    _transmit(command => 'vol_down');
}

sub action_cd_play {
    _transmit(command => 'cd_play');
}

sub action_wait {
    sleep(1);
}

foreach my $command (@ARGV) {
    no strict 'refs';
    my $function = 'action_'.$command;
    if (defined &{$function}) {
        say "Run command $command";
        &{$function}()
    }
}

$ir->close;
