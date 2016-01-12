#!/usr/bin/env perl

use Test::Most;

use Types::SQL qw/ Text /;
use Types::SQL::Util;

subtest 'no size' => sub {

    no warnings 'void';

    my $type = Text, 'Text';

    isa_ok $type => 'Type::Tiny';

    my %info = column_info_from_type($type);

    is_deeply \%info => {
        data_type  => 'text',
        is_numeric => 0,
      },
      'column_info'
      or note( explain \%info );

};

done_testing;
