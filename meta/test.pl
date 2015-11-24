#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use lib qw(lib/);

use Device::IRToy;

my $ir = Device::IRToy->new( port => '/dev/tty.usbmodem00000001' );
local $SIG{INT} = sub { die('Interupt') };

$ir->reset();
$ir->version();
$ir->sampling_mode();
receive();

#$ir->transmit(qw(0 171 0 92 0 18 0 26 0 17 0 70 0 19 0 26 0 17 0 69 0 18 0 26 0 17 0 69 0 19 0 26 0 17 0 69 0 18 0 26 0 17 0 69 0 20 0 26 0 17 0 68 0 19 0 69 0 19 0 26 0 17 0 69 0 18 0 26 0 17 0 69 0 18 0 68 0 19 0 69 0 19 0 69 0 18 0 26 0 17 0 26 0 17 0 69 0 19 0 68 0 19 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 70 0 18 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 69 0 19 0 69 0 18 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 27 0 17 0 69 0 18 0 26 0 17 0 26 0 17 0 26 0 17 0 69 0 19 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 69 0 20 0 26 0 17 0 26 0 17 0 26 0 16 0 70 0 19 0 26 0 17 0 26 0 17 0 26 0 17 0 69 0 18 0 69 0 18 0 26 0 17 0 71 0 18 0 26 0 17 0 26 0 17 0 26 0 16 0 27 0 16 0 27 0 16 0 27 0 17 0 70 0 18 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 16 0 28 0 16 0 27 0 16 0 27 0 16 0 27 0 16 0 27 0 17 0 26 0 17 0 26 0 17 0 70 0 18 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 27 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 68 0 19 0 68 0 19 0 68 0 19 0 70 0 19 0 68 0 19 0 26 0 17 0 26 0 17 0 26 0 17 0 26 0 17 0 68 0 19 0 26 0 17 0 26 0 17));
#read_sharp();
#$ir->transmit_protocol('Denon',{
#          'count' => 1,
#          'length' => 10,
#          'value' => 40,
#          'module' => 6
#        });

#$ir->transmit_raw(0x00,0x00,0x00,0x6d,0x00,0x00,0x00,0x20,0x00,0x0b,0x00,0x1d,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x06,0xf4,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x1e,0x00,0x0a,0x00,0x46,0x00,0x0a,0x00,0x46,0x00,0x0a,0x06,0x54);

sub receive {
    	while(1) {
        my $res = $ir->receive( timeout => 60_000_000, ,maxsignal => 25000);
        use Data::Dumper;
        {
          local $Data::Dumper::Maxdepth = 2;
          warn __FILE__.':line'.__LINE__.':'.Dumper($res);
        };
    }
}

sub read_denon {
    my $res = $ir->recieve( timeout => 60_000_000, protocol => 'Denon' );
    
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper($res);
    };
}
sub read_sharp {
    my $res = $ir->recieve( timeout => 60_000_000, protocol => 'Panasonic' );
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
