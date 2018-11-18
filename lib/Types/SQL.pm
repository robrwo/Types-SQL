package Types::SQL;

use v5.8;

use strict;
use warnings;

use Type::Library
  -base,
  -declare => qw/ Char Integer Numeric Serial Text Varchar /;

use Ref::Util qw/ is_arrayref /;
use Type::Utils 0.44 -all;
use Types::Standard -types;
use PerlX::Maybe;

use namespace::autoclean;

# RECOMMEND PREREQ: PerlX::Maybe::XS
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

# ABSTRACT: a library of SQL types

our $VERSION = 'v0.3.2';

=for Pod::Coverage VERSION

=cut

sub VERSION { # for older Perls
    my ( $class, $wanted ) = @_;
    require version;
    return version->parse($VERSION);
}

=head1 SYNOPSIS

  use Types::SQL -types;

  my $type = Varchar[16];

=head1 DESCRIPTION

This module provides a type library of SQL types.  These are
L<Type::Tiny> objects that are augmented with a C<dbic_column_info>
method that returns column information for use with
L<DBIx::Class>.

=for readme stop

=head1 TYPES

The following types are provided:

=head2 C<Blob>

  my $type = Blob;

Returns a C<blob> data type.

=cut

our $Blob = _generate_type(
    name             => 'Blob',
    parent           => Str,
    dbic_column_info => sub {
        my ($self) = @_;
        return (
            is_numeric => 0,
            data_type  => 'blob',
        );
    },
);

=head2 C<Text>

  my $type = Text;

Returns a C<text> data type.

=cut

our $Text = _generate_type(
    name             => 'Text',
    parent           => Str,
    dbic_column_info => sub {
        my ($self) = @_;
        return (
            is_numeric => 0,
            data_type  => 'text',
        );
    },
);

=head2 C<Varchar>

  my $type = Varchar[ $size ];

Returns a C<varchar> data type, with an optional size parameter.

=cut

our $Varchar = _generate_type(
    name                 => 'Varchar',
    parent               => $Text,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type => 'varchar',
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Char>

  my $type = Char[ $size ];

Returns a C<char> data type, with an optional size parameter.

=cut

our $Char = _generate_type(
    name                 => 'Char',
    parent               => $Text,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type => 'char',
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Integer>

  my $type = Integer[ $precision ];

Returns a C<integer> data type, with an optional precision parameter.

=cut

our $Integer = _generate_type(
    name                 => 'Integer',
    parent               => Int,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        return (
            data_type  => 'integer',
            is_numeric => 1,
            maybe size => $size || $self->type_parameter,
        );
    },
);

=head2 C<Serial>

  my $type = Serial[ $precision ];

Returns a C<serial> data type, with an optional precision parameter.

=cut

our $Serial = _generate_type(
    name                 => 'Serial',
    parent               => $Integer,
    constraint_generator => \&_size_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        my $parent = $self->parent->my_methods->{dbic_column_info};
        return (
            $parent->( $self->parent, $size || $self->type_parameter ),
            data_type         => 'serial',
            is_auto_increment => 1,
        );
    },
);

=head2 C<Numeric>

  my $type = Numeric[ $precision, $scale ];

Returns a C<integer> data type, with optional precision and scale parameters.

If C<$scale> is omitted, then it is assumed to be C<0>.

=cut

our $Numeric = _generate_type(
    name                 => 'Numeric',
    parent               => Num,
    constraint_generator => \&_size_range_constraint_generator,
    dbic_column_info     => sub {
        my ( $self, $size ) = @_;
        return (
            data_type  => 'numeric',
            is_numeric => 1,
            maybe size => $size || $self->parameters,
        );
    },
);

sub _size_constraint_generator {
    if (@_) {
        my ($size) = @_;
        die "Size must be a positive integer" unless $size =~ /^[1-9]\d*$/;
        my $re = qr/^0*\d{1,$size}$/;
        return sub { $_ =~ $re };
    }
    else {
        return sub { $_ =~ /^\d+$/ };
    }
}

sub _size_range_constraint_generator {
    if (@_) {
        my ( $prec, $scale ) = @_;
        $scale ||= 0;

        die "Precision must be a positive integer" unless $prec =~ /^[1-9]\d*$/;
        die "Scale must be a positive integer"     unless $scale =~ /^\d+$/;

        my $left = $prec - $scale;
        die "Scale must be less than the precision" if ( $left < 0 );

        my $re = qr/^0*\d{0,$left}([.]\d{0,$scale}0*)?$/;
        return sub { $_ =~ $re };
    }
    else {
        return sub { $_ =~ /^\d+$/ };
    }
}

sub _generate_type {
    my %args = @_;

    $args{my_methods} =
      { maybe dbic_column_info => delete $args{dbic_column_info}, };

    my $type = Type::Tiny->new(%args);
    __PACKAGE__->meta->add_type($type);
    return $type;
}

=head1 CUSTOM TYPES

Any type that has these types as a parent can have column information
extracted using L<Types::SQL::Util>.

Alternatively, you can specify a custom C<dbic_column_info> method in
a type, e.g.:

  my $type = Type::Tiny->new(
    name       => 'MyType',
    my_methods => {
      dbic_column_info => sub {
        my ($self) = @_;
        return (
           data_type    => 'custom',
           parameter    => 1234,
        );
      },
    },
    ...
  );

The method should return a hash of values that are passed to the
C<add_column> method of L<DBIx::Class::ResultSource>.

=for readme continue

=head1 ROADMAP

Support for Perl versions earlier than 5.10 will be removed sometime
in 2019.

=head1 SEE ALSO

L<Type::Tiny>.

L<Types::SQL::Util>, which provides a utility function for translating
these types and other types from L<Types::Standard> into column
information for L<DBIx::Class::ResultSource>.

=cut

__PACKAGE__->meta->make_immutable;
