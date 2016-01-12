package Types::SQL;

# ABSTRACT: A library of SQL types

use strictures;

use version;
$Types::SQL::VERSION = version->declare('v0.0.1');

use Type::Library
  -base,
  -declare => qw/ Char Integer Numeric Serial Text Varchar /;

use Ref::Util qw/ is_arrayref /;
use Type::Utils -all;
use Types::Standard -types;
use PerlX::Maybe;

# RECOMMEND PREREQ: PerlX::Maybe::XS
# RECOMMEND PREREQ: Type::Tiny::XS

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

1;
