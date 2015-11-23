#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use lib qw(lib/);

use Device::IRToy;

my $ir = Device::IRToy->new( port => '/dev/tty.usbmodem00000001' );
local $SIG{INT} = sub { die('Interupt') };

$ir->reset();
$ir->reset();
version();
$ir->sampling_mode();

#$ir->transmit(qw(74 90 20 24 18 69 20 24 18 69 19 24 18 69 19 24 18 68 20 24 18 68 22 23 18 68 19 67 20 24 18 69 19 24 18 68 20 68 19 68 20 67 20 24 18 25 18 68 20 68 19 24 18 25 18 25 18 25 18 69 21 23 18 25 18 25 18 69 19 67 21 68 19 24 18 25 18 25 18 26 18 25 18 69 19 24 18 25 18 25 18 68 21 67 19 24 18 25 18 25 20 67 21 23 18 25 18 25 18 69 19 24 18 25 18 69 19 24 18 69 21 23 18 68 21 23 18 25 18 25 18 25 18 25 18 25 18 68 20 24 18 25 18 26 18 25 18 25 18 25 18 25 18 25 18 25 18 25 18 25 18 68 20 23 18 25 18 70 19 24 18 25 18 25 18 25 18 25 18 25 18 25 18 25 18 25 18 68 20 67 22 68 19 67 20 68 20 24 19 24 18 25 18 25 18 68 20 68 20 24 19));
read_ir();

sub read_ir {
    my @res = $ir->read( timeout => 60_000 );
    say join " ",@res;
while(1) {
    my $res = $ir->recieve( timeout => 60_000_000, ,maxsignal => 25000);
    
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper($res);
    };
}



sub version {
    $ir->version;
}

sub blink {
    for (1..3) {
        say('run');
        $ir->write_raw(0x12);
        sleep(1);
        $ir->write_raw(0x13);
        sleep(1);
    }
}