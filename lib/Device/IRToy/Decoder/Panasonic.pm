package Device::IRToy::Decoder::Panasonic {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    
    sub decode {
        my ( $data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my $min = 0xffff;
        my $mul = $Device::IRToy::SCALE;
        my $dw  = 0;
        
        foreach (@$data) {
            $min = $_
                if $min > $_;
        }
        
        my $r0 = $data->[0] * $Device::IRToy::SCALE;
        if ( !Device::IRToy::Utils::fuzzy_chk( round( $r0 / 100 ), 35, 10 ) ) {
            log('WARN',"Probably not IR-PAN! First period:%.4fus 3500us(+/-1000) expected");
            return 0;
        }
        # TODO
    }
}