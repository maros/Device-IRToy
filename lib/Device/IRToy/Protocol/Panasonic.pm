package Device::IRToy::Protocol::Panasonic {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    use List::Util qw(min);
    
    sub encode {
        my ( $class,$data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my @encoded = (3700,1900);
        foreach my $byte (@{$data}) {
            for (reverse(0..7)) {
                if ($byte & 2**$_) {
                    push(@encoded,360,1500);
                } else {
                    push(@encoded,360,550);
                }
            }
        }
        
        
        return \@encoded;
    }
    
    sub decode {
        my ( $class,$data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my $min     = min(@$data);
        my $dw      = 0;
        
        if ( !Device::IRToy::Utils::check_fuzzy(  $data->[0], 3500, 1000 ) ) {
            msg('WARN',"Probably not Panasonic! First period:%%.4fµs 3500µs(+/-1000) expected");
            return;
        }
        
        if ( !Device::IRToy::Utils::check_fuzzy( $data->[1], 1500, 500 ) ) {
            msg('WARN',"Probably not Panasonic! Second period:%%.4fµs 1500µs(+/-500) expected");
            return;
        }
        
        my ($j,$i);
        my @result = ();
        
        my $bytes = ( $#{$data} - 2 ) / 16;
        for ($i = 0; $i < ( $#{$data} - 2 ) / 16; $i++ ) {
            my $bit = 7;
            $result[$i] = 0;
            for ( $j = 0; $j < 16; $j += 2 ) {
                $result[$i] |= 1 << ($bit) 
                    if $data->[3+16*$i+$j] > ( $min * 2 );
                $bit--;
            }
        }
        
        my $check = 2+16*($i-1)+$j;
        if ( $check != $#{$data} ) {
            msg('WARN',"Stop bit missing: %i != %i",$check,$#{$data});
        }
        
        return \@result;
    }
}

1;
