package Device::IRToy::Protocol::Panasonic {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    use List::Util qw(min);
    
    sub decode {
        my ( $class,$data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my $min     = min(@$data);
        my $scale   = $Device::IRToy::SCALE;
        my $dw      = 0;
        
        if ( !Device::IRToy::Utils::check_fuzzy( Device::IRToy::Utils::round( $data->[0] * $scale / 100 ), 35, 10 ) ) {
            msg('WARN',"Probably not IR-PAN! First period:%.4fµs 3500µs(+/-1000) expected");
            return 0;
        }
        
        if ( !Device::IRToy::Utils::check_fuzzy( Device::IRToy::Utils::round( $data->[1] * $scale / 100 ), 15, 5 ) ) {
            msg('WARN',"Probably not IR-PAN! Second period:%.4fµs 1700µs(+/-1000) expected");
            return 0;
        }
        
        msg('INFO','OK');
        
        my ($j,$i) = (0,0);
        my @result = ();
        
        my $bytes = ( $#{$data} - 2 ) / 16;
        for (my $i = 0; $i < ( $#{$data} - 2 ) / 16; $i++ ) {
            my $bit = 7;
            $result[$i] = 0;
            for ( $j = 0; $j < 16; $j+=2 ) {
                $result[$i] |= 1 << ($bit) 
                    if $data->[3+16*$i+$j] > ( $min * 2 );
                $bit--;
            }
        }
        
        my $check = 2+16*($i-1)+$j;
        if ( $check != $#{$data} ) {
            msg('WARN',"Bit missing: %d != %d",$check,$#{$data});
        }
        
        return \@result;
    }
}

1;
