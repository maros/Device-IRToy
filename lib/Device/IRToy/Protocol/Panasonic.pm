package Device::IRToy::Protocol::Panasonic {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    use List::Util qw(min);
    
    my @INIT = (3700,1900);
    
    sub maxsignal {
        return 4500;
    }
    
    sub encode {
        my ( $class,$data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my @encoded = @INIT;
        foreach my $byte (@{$data}) {
            for (reverse(0..7)) {
                if ($byte & 2 ** $_) {
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
        
        for my $index (0..$#INIT) {
            if ( !Device::IRToy::Utils::check_fuzzy(  $data->[$index], $INIT[$index], 1000 ) ) {
                msg('WARN',"Probably not Panasonic! period %i:%%.4fµs %iµs(+/-1000) expected",$index,$INIT[$index]);
                return;
            }
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
