package Device::IRToy::Utils {
    use 5.016;
    use warnings;
    
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(msg fatal);
    our @EXPORT_OK = qw(check_fuzzy);
    
    use Carp qw(croak);
    
    sub check_fuzzy {
        my ( $v, $c, $fuzz ) = @_;
        return ( $v < ( $c + $fuzz ) && $v > ( $c - $fuzz ) );
    }
    
    sub msg {
        my ($loglevel,$message,@sprintf) = @_;
        $message = sprintf($message,@sprintf);
        say '['.$loglevel.'] '.$message;
        return $message;
    }
    
    sub fatal {
        my (@message) = @_;
        my $message = msg('FATAL',@message);
        croak $message;
    }
}