package Device::IRToy::Protocol::Aermec {
    use 5.016;
    use warnings;

    use Device::IRToy::Utils;
    use List::Util qw(min);

    my @INIT    = (9000,4500);
    my $PERIOD  = 600;

    sub maxsignal {
        return 40000;
    }

    sub encode {
        my ( $class,$data ) = @_;

        return
            unless defined $data;

        my @encoded = @INIT;
        foreach my $bit (split //, unpack("b*",$data)) {
            push(@encoded,600);
            push(@encoded,$bit ? 1650 : 600);
        }

        return \@encoded;
    }

    sub decode {
        my ( $class,$data ) = @_;

        return
            unless defined $data
            && ref $data eq 'ARRAY'
            && scalar(@{$data}) > 2;

        my @process = @{$data};
        my $valid   = 0;
        my $check;
        while ($valid < scalar @INIT
            && scalar(@process)) {
            $check = shift(@process);
            if (Device::IRToy::Utils::check_fuzzy( $check, $INIT[$valid], 250 )) {
                $valid++;
            } else {
                $valid = 0;
            }
        }

        unless ($valid == scalar @INIT) {
            msg('WARN',"Probably not Aermec! period %i %iµs(+/-250) expected. Got %i",$valid,$INIT[$valid],$check);
            return;
        }

        my @result;
        my $pos = 0;
        for (my $i = 0; $i <= $#process; $i++) {
            my $len = $process[$i];
            if ($len > 19_000) {
                next;
            } else {
                if ($i % 2 == 1) {
                    if (Device::IRToy::Utils::check_fuzzy( $len, 1650, 150 )) {
                        push(@result,1);
                    } elsif (Device::IRToy::Utils::check_fuzzy( $len, 600, 150 )) {
                        push(@result,0);
                    } else {
                        msg('WARN','Invalid pause %i',$len);
                    }
                }
            }
        }

        return pack("b*", join("",@result));
    }
}

1;
