package Device::IRToy::Protocol::Denon {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    
#    #          1,
#          1,
#          0,
#          0,
#          0,
#          1,
#          1,
#          1,
#          0,
#          0,
#          1,
#          1,
#          1,
#          0,
#          0,
#          1,
#          1,
#          0,
#          1,
#          1,
#          0,
#          0,
#          0, 
#    
#          213,
#          811,
#          213,
#          811,
#          213,
#          1877,
#          213,
#          1856,
#          213,
#          811,
#          213,
#          811,
#          213,
#          811,
#          213,
#          811,
#          213,
#          811,
#          213,
#          1877,
#          213,
#          811,
#          213,
#          1856,
#          213,
#          811,
#          213,
#          811,
#          213,
#          811,
#          213,
#          47189,
#          256,
#          768,
#          256,
#          768,
#          256,
#          1813,
#          256,
#          1813,
#          256,
#          768,
#          256,
#          1835,
#          256,
#          1835,
#          213,
#          1877,
#          256,
#          1813,
#          277,
#          768,
#          256,
#          1813,
#          277,
#          768,
#          256,
#          1813,
#          256,
#          1835,
#          256,
#          1856,
#          256,
#          40725,
#          256,
#          768,
#          256,
#          789,
#          256,
#          1813,
#          277,
#          1835,
#          256,
#          768,
#          256,
#          789,
#          256,
#          789,
#          256,
#          768,
#          256,
#          789,
#          256,
#          1835,
#          256,
#          768,
#          256,
#          1835,
#          256,
#          747,
#          277,
#          747,
#          277,
#          747,
#          277,
#          47147,
#          256,
#          768,
#          235,
#          789,
#          235,
#          1856,
#          256,
#          1835,
#          277,
#          768,
#          277,
#          1813,
#          277,
#          1813,
#          277,
#          1813,
#          277,
#          1813,
#          277,
#          768,
#          277,
#          1813,
#          277,
#          768,
#          277,
#          1792,
#          277,
#          1835,
#          277,
#          1813,
#          277,
#          40704,
#          277,
#          768,
#          277,
#          789,
#          256,
#          1813,
#          277,
#          1813,
#          277,
#          768,
#          277,
#          768,
#          256,
#          768,
#          277,
#          768,
#          256,
#          768,
#          256,
#          1813,
#          256,
#          768,
#          256,
#          1813,
#          256,
#          768,
#          235,
#          789,
#          235,
#          811,
#          213,
#          47168,
#          213,
#          811,
#          213,
#          811,
#          213,
#          1877,
#          213,
#          1877,
#          213,
#          811,
#          213,
#          1877,
#          213,
#          1877,
#          213,
#          1877,
#          213,
#          1877,
#          213,
#          811,
#          213,
#          1877,
#          213,
#          811,
#          213,
#          1877,
#          192,
#          1899,
#          213,
#          1899,
#          192,
    
    sub decode {
        my ( $class,$data ) = @_;
        
        use Data::Dumper;
        {
          local $Data::Dumper::Maxdepth = 2;
          warn __FILE__.':line'.__LINE__.':'.Dumper($data);
        }
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my @result;
        for (my $i = 0; $i <= $#{$data}; $i++) {
            if ($i % 2 == 0) {
                if (!Device::IRToy::Utils::check_fuzzy($data->[$i],250,100)) {
                    msg('WARN',"Probably not Denon1! Low period:250µs(+/-100) expected,");
                    return;
                }
            } else {
                if (Device::IRToy::Utils::check_fuzzy($data->[$i],1850,100)) {
                    push(@result,1);
                } elsif (Device::IRToy::Utils::check_fuzzy($data->[$i],780,100)) {
                    push(@result,0);
                } elsif (Device::IRToy::Utils::check_fuzzy($data->[$i],47,100)) {
                } else {
                    msg('WARN',"Probably not Denon1! High period:1850µs or 780µs(+/-100) expected: %i",$data->[$i]);
                }
            }
        }
        
        return \@result;
    }
}

1;
