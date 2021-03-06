#!/usr/bin/env perl

use Test::Most;

use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Types::Common::Numeric -types;
use Types::SQL::Util;
use Types::Standard -types;

subtest 'Int' => sub {

    my $type = Int;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => { data_type => 'integer', is_numeric => 1, },
      'column_info'
      or note( explain \%info );

};

subtest 'SingleDigit' => sub {

    my $type = SingleDigit;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'integer',
        is_numeric => 1,
        size       => 1,
        extra      => { unsigned => 1 }
      },
      'column_info'
      or note( explain \%info );

};

subtest 'PositiveOrZeroInt' => sub {

    my $type = PositiveOrZeroInt;

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info =>
      { data_type => 'integer', is_numeric => 1, extra => { unsigned => 1 } },
      'column_info'
      or note( explain \%info );

};

subtest 'maybe int' => sub {

    my $type = Maybe [Int];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'integer',
        is_numeric  => 1,
        is_nullable => 1,
      },
      'column_info'
      or note( explain \%info );

};

subtest 'int[]' => sub {

    my $type = ArrayRef [Int];

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type   => 'integer[]',
        is_numeric  => 1,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;
