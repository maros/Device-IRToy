#!/usr/bin/env perl

use strict;
use 5.016;
use lib qw(lib/);

use Device::IRToy;

sub transmit {
    my ($code,$count) = @_;
    $count //= 1;
    
    state $ir = Device::IRToy->new( port => '/dev/tty.usbmodem00000001' );
    $ir->transmit_protocol(
        'Denon',
        {
            count   => $count,
            code    => $code,
            length  => 10,
            module  => 6
        }
    );
}

sub sleep {
    my ($duration) = @_;
    
    $duration //= 60;
    $duration = int($duration / 10) * 10;
    
    for (my $i = 60; $i <= $duration; $i -= 10) {
        transmit(312);
        sleep(1);
    }
}

sub power {
    transmit(40);
}

sub tuner {
    transmit(616);
}

sub aux {
    tuner();
    sleep(1);
    transmit(1000);
    sleep(1);
    transmit(1000);
}

sub vol_up {
    my ($level) = @_;
    $level //= 1;
    transmit(712,$level);
}

sub vol_down {
    my ($level) = @_;
    $level //= 1;
    transmit(200,$level);
}