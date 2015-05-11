package Device::IRToy {
    use 5.016;
    use Moose;
    use Time::HiRes qw(usleep);
    use Carp qw(croak);
    
    our $SLEEP_USECONDS = 5000;
    our $SCALE = 21.33333;
    
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
    
    sub log {
        my ($self,$loglevel,$message,@sprintf) = @_;
        $message = sprintf($message,@sprintf);
        say '['.$loglevel.'] '.$message;
        return $message;
    }
    
    sub fatal {
        my ($self,@message) = @_;
        my $message = $self->log('FATAL',@message);
        croak $message;
    }
    
    sub DEMOLISH {
        my ($self) = @_;
        if ($self->has_serial) {
            $self->log('INFO','Closing serial port');
            $self->serial->close();
        }
    }
    
    sub _build_serial {
        my ($self) = @_;
        
        my $serial;
        if ($^O eq 'MSWin32') {
            require Win32::SerialPort;
            $serial = new Win32::SerialPort($self->port)
                or $self->fatal("Can't open serial port! Win32::SerialPort(".$self->port.")");
        } else {
            require Device::SerialPort;
            $serial = new Device::SerialPort($self->port)
                or $self->fatal("Can't open serial port! Device::SerialPort(".$self->port.")");
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
            or $self->fatal("Can't initialise serial port settings");
        
        $self->log('INFO','Initialized serial port');
        
        return $serial;
    }
    
    
    # sends commands to reset USBIRToy
    sub reset {
        my ($self) = @_;
        $self->log('INFO','Run reset');
        $self->write_raw((0x00) x 5);
    }
    
    # enable sampling mode
    sub sampling_mode {
        my ($self) = @_;
        
        $self->reset();
        
        $self->log('INFO','Initializing sampling mode');
        $self->write_raw( ord('s') );
        usleep($SLEEP_USECONDS);
        
        my $res = $self->read_raw(bytes => 3);
        if ( defined $res 
            && $res =~ /S(\d\d)$/ ) {
            $self->log('DEBUG','Initialized sampling mode: API version %s',$res);
            return 1;
        } else {
            $self->fatal('Could not initialize sampling mode');
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
        if ($version =~ /^V(\d)(\d\d)$/) {
            $self->log('WARN','Version 22 is recommended. This is only %i',$2)
                if $2 < 22;
            return ($1,$2);
        } else {
            $self->fatal('Could not read version');
        }
    }
    
    sub transmit {
        my ($self,@data) = @_;
        
        if (scalar @data < 2
            || scalar @data % 2 != 0) {
            $self->fatal('Transmit data must be even sized list with a minimum of two bytes');
        }
        
        unless ($data[-2] eq 0xff 
            && $data[-1] eq 0xff) {
            push(@data,0xff,0xff);
        }
        
        $self->log('DEBUG','About to transmit %i bytes',scalar(@data));
        
        usleep($SLEEP_USECONDS);
        
        $self->write_raw(
            0x26,   # enable handshake
            0x25,   # enable notify on transmit
            0x24,   # enable transmit byte count
            0x03,   # start transmission
        );
        
        usleep($SLEEP_USECONDS);
        
        my $bytes =  $self->write_raw(@data);
#        while (scalar @data) {
#            $self->log('DEBUG','Loop block');
#            my @send = splice @data,0,32;
#            $bytes += $self->write_raw(@send);
#            #my $handshake = ord($self->read_raw(bytes => 1));
#            #say "HANDSHAKE: $handshake";
#        }
        
        usleep($SLEEP_USECONDS);
        
        $self->log('DEBUG','Get report');
        my $report = $self->read_raw(bytes => 1);
        
        unless (lc($report) eq 'c') {
            $self->log('ERROR','Could not transmit IR code Report: %s',$report);
        }
        
        $self->sampling_mode();
    }
    
    sub write_raw {
        my ($self,@data) = @_;
        
        my $total = scalar @data;
        my $bytes = 0;#
    
        while (scalar @data) {
            my @send = splice @data,0,32;
            my $send = pack( "a" x scalar @send, (map { pack( "C", $_ & 0xff ) } @send));
            $self->log('DEBUG','About to write %i bytes',scalar(@send));
            $bytes += $self->serial->write( $send );
        }
        
        unless ($total == $bytes) {
            $self->fatal('Incorrect number of bytes written. Expected %i, got',scalar @data,$bytes);
        }
        return $bytes;
    }
    
    sub read_raw {
        my ($self,%params) = @_;
        
        $params{timeout} //= 500;      # in miliseconds
        my $tries = int($params{timeout} / $self->serial->read_const_time);
        
        my $loopcount = 0;
        my $data = '';
        my $errorcount = 0;
        
        $self->log('DEBUG','About to read data');
        while ( my ( $read_ok, $read_byte ) = $self->serial->read(1) ) {
            if ( $read_ok == 0 ) {
                if ($data ne '') {
                    last;
                } elsif ( $loopcount++ > $tries) {
                    $self->log('DEBUG','Read timeout');
                    return;
                }
                usleep(100);
            } else {
                if (defined $params{bytes}
                    && ord($read_byte) == 0xff) {
                    $self->log('DEBUG','Got 0xff - ignoring');
                    $errorcount++;
                    if ($errorcount >= 6) {
                        $self->log('WARN','Read timeout');
                    }
                    next;
                }
                #say "READ ".$read_byte;
                say '_'.unpack("C",$read_byte);
                $data .= $read_byte;
                if (defined $params{bytes}
                    && length($data) >= $params{bytes}) {
                    last;
                }
            }
        }
        $self->log('DEBUG','Read %s',$data);
        return $data;
    }
    
    sub read {
        my ($self,%params) = @_;
        
        my $data = $self->read_raw(%params);
        return
            unless defined $data;
        
        my @return;
        while (length $data) {
            my ($hb,$lb) = split (//,substr($data,0,2,''));
            push(@return,ord($hb)*(2**8)+ord($lb));
        }
        return @return;
    }
    __PACKAGE__->meta->make_immutable();
}