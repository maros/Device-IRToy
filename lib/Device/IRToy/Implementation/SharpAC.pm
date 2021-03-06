package Device::IRDefinition::SharpAC;
use utf8;
use 5.016;

my $DATA = '01010101010110101111001100001000______0_1000___0___0___0_____000___1000000000001___0000000_011111000____';

#56-60 ...
#    ... 10101 default
#    ... 00000 full power
#50 ... ???
#66 ... toggle pro_airflow
#46 ... toggle ion
#80 ... non-default fan
#81 ... toggle pro_airflow
#82 ... non-default temp


my %VARIABLES = (
    temperature     => {
        'none'          => { 32 => 0, 33 => 0, 34 => 0, 35 => 0 },
        '18'            => { 32 => 1, 33 => 0, 34 => 0, 35 => 0 },
        '19'            => { 32 => 0, 33 => 1, 34 => 0, 35 => 0 },
        '20'            => { 32 => 1, 33 => 1, 34 => 0, 35 => 0 },
        '21'            => { 32 => 0, 33 => 0, 34 => 1, 35 => 0 },
        '22'            => { 32 => 1, 33 => 0, 34 => 1, 35 => 0 },
        '23'            => { 32 => 0, 33 => 1, 34 => 1, 35 => 0 },
        '24'            => { 32 => 1, 33 => 1, 34 => 1, 35 => 0 },
        '25'            => { 32 => 0, 33 => 0, 34 => 0, 35 => 1 },
        '26'            => { 32 => 1, 33 => 0, 34 => 0, 35 => 1 },
        '27'            => { 32 => 0, 33 => 1, 34 => 0, 35 => 1 },
        '28'            => { 32 => 1, 33 => 1, 34 => 0, 35 => 1 },
        '29'            => { 32 => 0, 33 => 0, 34 => 1, 35 => 1 },
        '30'            => { 32 => 1, 33 => 0, 34 => 1, 35 => 1 },
        '31'            => { 32 => 0, 33 => 1, 34 => 1, 35 => 1 },
        '32'            => { 32 => 1, 33 => 1, 34 => 1, 35 => 1 },
    },
    temperature_diff  => {
        '-2'            => { 36 => 0, 37 => 1, 39 => 1 },
        '-1'            => { 36 => 1, 37 => 0, 39 => 1 },
        '0'             => { 36 => 0, 37 => 0, 39 => 0 },
        '+1'            => { 36 => 1, 37 => 0, 39 => 0 },
        '+2'            => { 36 => 0, 37 => 1, 39 => 0 },
    },
    full            => {
        'off'           => { 44 => 1 },
        'on'            => { 44 => 0 },
    },
    ac              => {
        'off'           => { 45 => 1 },
        'on'            => { 45 => 0 },
    },
    mode            => {
        'heat'          => { 48 => 1, 49 => 0 },
        'cool'          => { 48 => 0, 49 => 1 },
        'dry'           => { 48 => 1, 49 => 1 }, # temp -> temperature_diff, fan -> cycle
        'auto'          => { 48 => 0, 49 => 0 }, # temp -> temperature_diff, temp -> none
    },
    ion             => {
        'off'           => { 90 => 0 },
        'on'            => { 90 => 1 },
    },
    fan             => {
        'cycle'         => { 52 => 0, 53 => 1, 54 => 0 },
        'low'           => { 52 => 1, 53 => 1, 54 => 0 },
        'medium'        => { 52 => 1, 53 => 0, 54 => 1 },
        'high'          => { 52 => 1, 53 => 1, 54 => 1 },
    },
    pro_airflow     => {
        'off'           => { 64 => 1, 65 => 0 },
        'on'            => { 64 => 0, 65 => 1 },
    },
);


