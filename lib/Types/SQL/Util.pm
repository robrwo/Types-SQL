package Types::SQL::Util;

use strict;
use warnings;

use Exporter qw/ import /;

use PerlX::Maybe;
use Safe::Isa qw/ $_isa $_call_if_can /;

our $VERSION = 'v0.2.2';

# RECOMMEND PREREQ: PerlX::Maybe::XS

# ABSTRACT: extract DBIx::Class column_info from types

=head1 SYNOPSIS

  use Types::SQL -types;
  use Types::Standard -types;

  use Types::SQL::Util;

  my $type = Maybe[ Varchar[64] ];

  my %info = column_info_from_type( $type );

=head1 DESCRIPTION

This module provides a utility function that translates types into
column information.

=head1 EXPORTS

=function C<column_info_from_type>

  my %info = column_info_from_type( $type );

This function returns a hash of column information for the
C<add_column> method of L<DBIx::Class::ResultSource>, based on the
type.

Besides the types from L<Types::SQL>, it also supports the following
types from L<Types::Standard>, L<Types::Common::String>, and
L<Types::Common::Numeric>:

=head3 C<ArrayRef>

This treats the type as an array.

=head3 C<Bool>

This is treated as a C<boolean> type.

=head3 C<Enum>

This is treated as an C<enum> type, which can be used with
L<DBIx::Class::InflateColumn::Object::Enum>.

=head3 C<InstanceOf>

For L<DateTime>, L<DateTime::Tiny>, L<Time::Moment> and L<Time::Piece>
objects, this is treated as a C<datetime>.

=head3 C<Int>

This is treated as an C<integer> without a precision.

=head3 C<Maybe>

This treats the type in the parameter as nullable.

=head3 C<Num>

This is treated as a C<numeric> without a precision.

=head3 C<PositiveOrZeroInt>

This is treated as an C<unsigned integer> without a precision.

=head3 C<PositiveOrZeroNum>

This is treated as an C<unsigned numeric> without a precision.

=head3 C<SingleDigit>

This is treated as an C<unsigned integer> of size 1.

=head3 C<Str>

=head3 C<NonEmptyStr>

=head3 C<LowerCaseStr>

=head3 C<UpperCaseStr>

These are treated as a C<text> value without a size.

=head3 C<SimpleStr>

=head3 C<NonEmptySimpleStr>

=head3 C<LowerCaseSimpleStr>

=head3 C<UpperCaseSimpleStr>

These is trated as a C<text> value with a size of 255.

=cut

our @EXPORT    = qw/ column_info_from_type /;
our @EXPORT_OK = @EXPORT;

my %CLASS_TYPES = (
    'DateTime'       => 'datetime',
    'DateTime::Tiny' => 'datetime',
    'Time::Moment'   => 'datetime',
    'Time::Piece'    => 'datetime',
);

sub column_info_from_type {
    my ($type) = @_;

    return { } unless $type->$_isa('Type::Tiny');

    my $name    = $type->name;
    my $methods = $type->my_methods;
    my $parent  = $type->has_parent ? $type->parent : undef;

    if ( $type->is_anon && $parent ) {
        $name    = $parent->name;
        $methods = $parent->my_methods;
    }

    if ( $methods && $methods->{dbic_column_info} ) {
        return $methods->{dbic_column_info}->($type);
    }

    if ( $type->isa('Type::Tiny::Enum') ) {
        return (
            data_type  => 'enum',
            is_enum    => 1,
            is_numeric => 0,
            extra      => {
                list => $type->values,
            },
        );
    }

    if (   $name eq 'Maybe'
        && $parent->$_call_if_can('library') eq 'Types::Standard' )
    {
        return (
            is_nullable => 1,
            column_info_from_type( $type->type_parameter )
        );
    }

    if (   $name eq 'ArrayRef'
        && $parent->$_call_if_can('library') eq 'Types::Standard' )
    {
        my %type = column_info_from_type( $type->type_parameter );
        $type{data_type} .= '[]';
        return %type;
    }

    if (   $name eq 'Object'
        && $parent->$_call_if_can('library') eq 'Types::Standard'
        && $type->display_name =~ /^InstanceOf\[['"](.+)['"]\]$/ )
    {
        if ( my $data_type = $CLASS_TYPES{$1} ) {
            return ( data_type => $data_type );
        }

    }

    if ( $name eq 'Str'
         && $type->library eq 'Types::Standard' ) {
        return ( data_type => 'text', is_numeric => 0 );
    }

    if ( $name =~ /^(?:NonEmpty|LowerCase|UpperCase)?Str$/
         && $type->library eq 'Types::Common::String' ) {
        return ( data_type => 'text', is_numeric => 0 );
    }

    if ( $name =~ /^(?:NonEmpty|LowerCase|UpperCase)?SimpleStr$/
         && $type->library eq 'Types::Common::String' ) {
        return ( data_type => 'text', is_numeric => 0, size => 255 );
    }

    if ( $name eq 'Int'
        && $type->library eq 'Types::Standard' ) {
        return ( data_type => 'integer', is_numeric => 1 );
    }

    if (   $name eq 'SingleDigit'
        && $type->library eq 'Types::Common::Numeric' )
    {
        return (
            data_type  => 'integer',
            is_numeric => 1,
            size       => 1,
            extra      => { unsigned => 1 }
        );
    }

    if ( $name eq 'PositiveOrZeroInt'
         && $type->library eq 'Types::Common::Numeric' ) {
        return (
            data_type  => 'integer',
            is_numeric => 1,
            extra      => { unsigned => 1 }
        );
    }

    if ( $name eq 'Num'
         && $type->library eq 'Types::Standard' ) {
        return ( data_type => 'numeric', is_numeric => 1 );
    }

    if ( $name eq 'PositiveOrZeroNum'
         && $type->library eq 'Types::Common::Numeric' ) {
        return (
            data_type  => 'numeric',
            is_numeric => 1,
            extra      => { unsigned => 1 }
        );
    }

    if ( $name eq 'Bool'
         && $type->library eq 'Types::Standard' ) {
        return ( data_type => 'boolean' );
    }

    if ( $parent ) {
        my @info = eval { column_info_from_type( $parent ) };
        return @info if @info;
    }

    die "Unsupported type: " . $type->display_name;
}

=head1 CUSTOM TYPES

You can declare custom types from these types and still extract column
information from them:

  use Type::Library
    -base,
    -declare => qw/ CustomStr /;

  use Type::Utils qw/ -all /;
  use Types::SQL -types;
  use Types::SQL::Util;

  declare CustomStr, as Varchar [64];

  ...

  my $type = CustomStr;
  my %info = column_info_from_type($type);

=head1 SEE ALSO

L<Types::SQL>.

L<Types::Standard>

=cut

1;
