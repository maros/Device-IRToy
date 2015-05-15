package Device::IRToy {
    use 5.016;
    use utf8;
    
    use Moose;
    use Time::HiRes qw(usleep time);
    use Carp qw(croak);
    use List::Util qw(min);
    
    use Device::IRToy::Utils;
    
    our $SLEEP_USECONDS = 5000;         # µs
    our $SCALE = 21.3333;               # µs
    our $MAXSIGNAL = 0xffff * $SCALE;   # µs
    
    has 'port' => (
        is              => 'ro',
        isa             => 'Str',
        required        => 1,
    );
    
    has 'baudrate' => (
        is              => 'ro',
        isa             => 'Int',
        required        => 1,
        default         => '115200',
    );
    
    has 'serial' => (
        is              => 'ro',
        isa             => 'Ref',
        lazy            => 1,
        builder         => '_build_serial',
        predicate       => 'has_serial',
    );
    
    sub DEMOLISH {
        my ($self) = @_;
        if ($self->has_serial) {
            msg('INFO','Closing serial port');
            $self->serial->close();
        }
    }
    
    sub _build_serial {
        my ($self) = @_;
        
        my $serial;
        if ($^O eq 'MSWin32') {
            require Win32::SerialPort;
            $serial = new Win32::SerialPort($self->port)
                or fatal("Can't open serial port! Win32::SerialPort(".$self->port.")");
        } else {
            require Device::SerialPort;
            $serial = new Device::SerialPort($self->port)
                or fatal("Can't open serial port! Device::SerialPort(".$self->port.")");
        }
        
        $serial->baudrate( $self->baudrate );
        $serial->parity( 'none' );
        $serial->databits( 8 );
        $serial->stopbits( 1 );
        $serial->handshake( 'none' );
        $serial->buffers( 1, 1 );
        #$serial->read_interval(60);
        $serial->read_char_time(10);
        $serial->read_const_time(25);
        $serial->write_settings 
            or fatal("Can't initialise serial port settings");
        
        msg('INFO','Initialized serial port');
        
        return $serial;
    }
    
    # sends commands to reset USBIRToy
    sub reset {
        my ($self) = @_;
        msg('INFO','Run reset');
        $self->write_raw((0x00) x 5);
    }
    
    # enable sampling mode
    sub sampling_mode {
        my ($self) = @_;
        
        $self->reset();
        
        msg('INFO','Initializing sampling mode');
        $self->write_raw( ord('s') );
        usleep($SLEEP_USECONDS);
        
        my $res = $self->read_raw(
            bytes   => 3, 
            timeout => 2_000_000
        );
        if ( defined $res 
            && $res =~ /S(\d\d)$/ ) {
            msg('DEBUG','Initialized sampling mode: API version %s',$res);
            return 1;
        } else {
            fatal('Could not initialize sampling mode');
        }
        return 0;
    }
    
    sub version {
        my ($self) = @_;
        
        $self->reset();
        usleep($SLEEP_USECONDS);
        $self->write_raw( ord('v') );
        usleep($SLEEP_USECONDS);
        
        my $version = $self->read_raw(bytes => 4);
        
        if (defined $version 
            && $version =~ /^V(\d)(\d\d)$/) {
            msg('WARN','Version 22 is recommended. This is only %i',$2)
                if $2 < 22;
            return ($1,$2);
        } else {
            fatal('Could not read version');
        }
    }
    
    sub transmit {
        my ($self,%params) = @_;
        
        if (defined $params{protocol}) {
            my $protocol = $params{protocol};
            $protocol = 'Device::IRToy::Protocol::'.$protocol
                unless $protocol =~ /::/;
            Class::Load::load_class($protocol);
            msg('DEBUG','Try to encode via %s',$protocol);
            $params{data} = $protocol->encode($params{data});
        }
        
        my @data;
        foreach my $length (@{$params{data}}) {
            $length /= $SCALE;
            my $length_hex = sprintf("%04x",int($length));
            push(@data,hex(substr($length_hex,0,2)),hex(substr($length_hex,2,2)));
        }
        
        $self->transmit_raw(@data);
        
        return;
    }
    
    sub transmit_raw {
        my ($self,@data) = @_;
        
        if (scalar @data < 2
            || scalar @data % 2 != 0) {
            fatal('Transmit data must be even sized list with a minimum of two bytes');
        }
        
        # End data
        unless ($data[-2] eq 0xff 
            && $data[-1] eq 0xff) {
            push(@data,0xff,0xff);
        }
        
        msg('DEBUG','About to transmit %i bytes',scalar(@data));
        
        usleep($SLEEP_USECONDS);
        
        $self->write_raw(
            0x24,   # enable transmit byte count
            0x25,   # enable notify on transmit
            0x26,   # enable handshake
            0x03,   # start transmission
        );
        
        while (scalar @data) {
            # Read handshake
            my $buffer_size = $self->read_raw(bytes => 1);
            $buffer_size = ord($buffer_size);
            
            # Get block for buffer
            my @block = splice @data,0,$buffer_size;
            
            my $block_size = min($buffer_size,scalar @block);
            msg('DEBUG','Transmit %i bytes',$block_size);
            
            $self->write_raw(@block);
        }
        
        # Read left over handshake
        $self->read_raw(bytes => 1);
        
        # Read transmit count and complete notify
        my $transmit_report = $self->read_raw(bytes => 4);
        
        if ($transmit_report =~ m/^t(..)([CF])$/) {
            if ($2 eq 'C') {
                msg('INFO','Successfully transmitted ir code');
            } elsif ($2 eq 'F') {
                fatal('Buffer underrun during transmit');
            }
        } else {
            fatal('Could not parse transmit report: %s',$transmit_report);
        }
        
        $self->sampling_mode();
        return;
    }
    
    sub write_raw {
        my ($self,@data) = @_;
        
        my $send = pack( 
            "a" x scalar @data, 
            (map { pack( "C", $_ & 0xff ) } @data)
        );
        
        msg('DEBUG','About to write %i bytes',scalar(@data));
        my $bytes = $self->serial->write( $send );
        
        unless (scalar @data == $bytes) {
            fatal('Incorrect number of bytes written. Expected %i, got',scalar @data,$bytes);
        }
        return $bytes;
    }
    
    sub read_raw {
        my ($self,%params) = @_;
        
        $params{timeout} //= 500_000; # µs
        
        my $serial      = $self->serial;
        my $read_time   = ($serial->read_const_time + $serial->read_char_time) * 1000 + 200;
        my $tries       = int($params{timeout} / $read_time );
        my $loopcount   = 0;
        my $data        = '';
        my $errorcount  = 0;
        my $maxsignal   = defined $params{maxsignal} ? int($params{maxsignal} / $read_time) : 0;
        
        msg('DEBUG','About to read data');
        while ( my ( $read_ok, $read_byte ) = $serial->read(1) ) {
            if ( $read_ok == 0 ) {
                if ($data ne '') {
                    if ($maxsignal > 0
                        && $loopcount < $maxsignal) {
                        #warn "WAIT FOR SIGNAL $loopcount";
                        $loopcount++;
                    } else {
                        last;
                    }
                } elsif ( $loopcount++ > $tries) {
                    msg('DEBUG','Read timeout');
                    return;
                }
                usleep(100);
            } else {
                $loopcount = 0;
                if (defined $params{bytes}
                    && ord($read_byte) == 0xff) {
                    msg('DEBUG','Got 0xff - ignoring');
                    $errorcount++;
                    if ($errorcount >= 6) {
                        fatal('Read error');
                    }
                    next;
                } else {
                    $errorcount = 0;
                }
                #say "READ ".$read_byte;
                #say '_'.unpack("C",$read_byte);
                $data .= $read_byte;
                if (defined $params{bytes}
                    && length($data) >= $params{bytes}) {
                    last;
                }
            }
        }
        msg('DEBUG','Read %i bytes',length($data));
        return $data;
    }
    
    sub recieve {
        my ($self,%params) = @_;
        
        $params{maxsignal} ||= $MAXSIGNAL;
        
        my $data = $self->read_raw(%params);
        return
            unless defined $data;
        
        my @return;
        while (length $data) {
            my ($hb,$lb) = split (//,substr($data,0,2,''));
            my $length = ord($hb)*(2**8)+ord($lb);
            $length *= $SCALE;
            $length = int($length + 0.5);
            push(@return,$length);
        }
        
        if (defined $params{protocol}) {
            my $protocol = $params{protocol};
            $protocol = 'Device::IRToy::Protocol::'.$protocol
                unless $protocol =~ /::/;
            Class::Load::load_class($protocol);
            msg('DEBUG','Try to decode via %s',$protocol);
            return $protocol->decode(\@return);
        }
        
        return \@return;
    }
    __PACKAGE__->meta->make_immutable();
}