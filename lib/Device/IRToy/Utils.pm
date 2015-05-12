package Device::IRToy::Utils {
    use 5.016;
    use warnings;
    
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(log fatal);
    our @EXPORT_OK = qw(check_fuzzy);
    
    sub check_fuzzy {
        my ( $v, $c, $fuzz ) = @_;
        return ( $v < ( $c + $fuzz ) && $v > ( $c - $fuzz ) );
    }
    
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
}