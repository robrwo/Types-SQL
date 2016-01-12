#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

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

    ok !$type->check(undef), 'check (undef)';
    ok $type->check( '1' x $size ), 'check';
    ok !$type->check( 'x' x $size ), 'check';
    ok !$type->check( '1' x ( $size + 1 ) ), 'check';

};

subtest 'bad size' => sub {

    throws_ok {
        my $type = Integer ['x'];
    }
    qr/Size must be a positive integer/, 'invalid size';

};

done_testing;
