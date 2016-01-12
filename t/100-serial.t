#!/usr/bin/env perl

use Test::Most;

use Types::SQL qw/ Serial /;
use Types::SQL::Util;

subtest 'no size' => sub {

    no warnings 'void';

    my $type = Serial, 'Serial';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_numeric        => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    no warnings 'void';

    my $size = 12;
    my $type = Serial [$size], 'Serial';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_numeric        => 1,
        size              => $size,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'bad size' => sub {

    no warnings 'void';

    throws_ok {
        my $type = Serial ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;
