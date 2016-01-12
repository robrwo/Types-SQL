package Types::SQL;

# ABSTRACT: A library of SQL types

use strictures;

use version;
$Types::SQL::VERSION = version->declare('v0.0.1');

use Type::Library
  -base,
  -declare => qw/ Integer Serial Text Varchar /;

use Type::Utils -all;
use Types::Standard -types;
use PerlX::Maybe;

our $Text = Type::Tiny->new(
    name       => 'Text',
    parent     => Str,
    my_methods => {
        dbic_column_info => sub {
            return ( data_type => 'text', is_numeric => 0 );
        }

    },
);

__PACKAGE__->meta->add_type($Text);

our $Varchar = Type::Tiny->new(
    name                 => 'Varchar',
    parent               => $Text,
    constraint_generator => sub {
        if (@_) {
            my ($size) = @_;
            die "Size must be a positive integer" unless $size =~ /^[1-9]\d*$/;
            return sub { length($_) <= $size };
        }
        else {
            return sub { 1 };
        }
    },
    my_methods => {
        dbic_column_info => sub {
            my ($self) = @_;
            return (
                is_numeric => 0,
                data_type  => 'varchar',
                maybe size => $self->type_parameter,
            );
        }

    },
);

__PACKAGE__->meta->add_type($Varchar);

our $Integer = Type::Tiny->new(
    name                 => 'Integer',
    parent               => Int,
    constraint_generator => sub {
        if (@_) {
            my ($size) = @_;
            die "Size must be a positive integer" unless $size =~ /^[1-9]\d*$/;
            my $re = qr/^0*\d{1,$size}$/;
            return sub { $_ =~ $re };
        }
        else {
            return sub { $_ =~ /^\d+$/ };
        }
    },
    my_methods => {
        dbic_column_info => sub {
            my ( $self, $size ) = @_;
            return (
                data_type  => 'integer',
                is_numeric => 1,
                maybe size => $size || $self->type_parameter,
            );
        }

    },
);

__PACKAGE__->meta->add_type($Integer);

our $Serial = Type::Tiny->new(
    name                 => 'Serial',
    parent               => $Integer,
    constraint_generator => sub {
        if (@_) {
            my ($size) = @_;
            die "Size must be a positive integer" unless $size =~ /^[1-9]\d*$/;
            my $re = qr/^0*\d{1,$size}$/;
            return sub { $_ =~ $re };
        }
        else {
            return sub { $_ =~ /^\d+$/ };
        }
    },
    my_methods => {
        dbic_column_info => sub {
            my ( $self, $size ) = @_;
            my $parent = $self->parent->my_methods->{dbic_column_info};
            return (
                $parent->( $self->parent, $size || $self->type_parameter ),
                is_auto_increment => 1,

            );
        }

    },
);

__PACKAGE__->meta->add_type($Serial);

1;
