#!/usr/bin/env perl

use Test::Most;

use Types::SQL qw/ Varchar /;
use Types::SQL::Util;
use Types::Standard -types;

subtest 'no size' => sub {

    no warnings 'void';

    my $type = Varchar, 'Varchar';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'varchar',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'size' => sub {

    no warnings 'void';

    my $size = 12;
    my $type = Varchar [$size], 'Varchar';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'varchar',
        is_numeric => 0,
        size       => $size,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe size' => sub {

    no warnings 'void';

    my $size = 12;
    my $type = Maybe [ Varchar [$size] ], 'Varchar';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'varchar',
        is_numeric  => 0,
        size        => $size,
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'bad size' => sub {

    no warnings 'void';

    throws_ok {
        my $type = Varchar ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;
