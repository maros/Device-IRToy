package Device::IRToy::Protocol::Denon {
    use 5.016;
    use warnings;
    
    use Device::IRToy::Utils;
    
    our $PREFIX = '00';
    our $MODULE = 3;
    
    sub maxsignal {
        return 48_000;
    }
    
    sub decode {
        my ( $class,$data ) = @_;
        
        return
            unless defined $data
            && ref $data eq 'ARRAY';
        
        my $count   = 0;
        my ($result,$block) = ('','');
        for (my $i = 0; $i <= $#{$data}; $i++) {
            if ($data->[$i] > 1_250_000) {
                if ($block eq '') {
                    return;
                }
                next;
            }
            if ($i % 2 == 0) {
                if (!Device::IRToy::Utils::check_fuzzy($data->[$i],250,100)) {
                    msg('WARN',"Probably not Denon1! Low period 250µs(+/-100) expected: Got %i",$data->[$i]);
                    return;
                }
            } else {
                if (Device::IRToy::Utils::check_fuzzy($data->[$i],1850,100)) {
                    $block .= '1';
                } elsif (Device::IRToy::Utils::check_fuzzy($data->[$i],780,100)) {
                    $block .= '0';
                } elsif (Device::IRToy::Utils::check_fuzzy($data->[$i],44000,5000)) {
                    if ($count == 0) {
                        $result = $block;
                    } else {
                        my $block_data = substr($block,length($PREFIX)+$MODULE);
                        my $result_data = substr($result,length($PREFIX)+$MODULE);
                        if ($count % 2 != 0) {
                            $block_data =~ tr/01/10/;
                        }
                        if ($block_data ne $result_data) {
                            msg('WARN',"Repeated block does not match first block: %s vs %s",$block_data,$result_data);
                        }
                    }
                    $count++;
                    $block = '';
                } else {
                    msg('WARN',"Probably not Denon1! High period 1850µs or 780µs(+/-100) expected: Got %i",$data->[$i]);
                }
            }
        }
        
        my $prefix = substr($result,0,length($PREFIX),'');
        my $module = substr($result,0,$MODULE,'');
        
        if ($prefix ne $PREFIX) {
             msg('WARN',"Prefix does not match %s: Got %s",$PREFIX,$prefix);
        }
        
        $module = Device::IRToy::Utils::bit2int($module);
        my $return = Device::IRToy::Utils::bit2int($result);
        
        return { module => $module, value => $return, count => int($count/2) };
    }
}

1;
