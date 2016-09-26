package Device::IRToy::InterfaceProtocol {
    use 5.016;

    use Moose::Role;
    requires qw(encode decode maxsignal);
}

1;
