#!/usr/bin/env perl

use Test::Most;

use Types::SQL qw/ Integer /;
use Types::SQL::Util;

subtest 'no size' => sub {

    my $type = Integer;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'integer',
        is_numeric        => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    my $size = 12;
    my $type = Integer [$size];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type         => 'integer',
        is_numeric        => 1,
        size              => $size,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Integer ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;
