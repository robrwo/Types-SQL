package Types::SQL::Util;

# ABSTRACT: Extract DBIx::Class column_info from types

use strictures;

use version;
$Types::SQL::Util::VERSION = version->declare('v0.0.1');

use Exporter qw/ import /;

use PerlX::Maybe;

# RECOMMEND PREREQ: PerlX::Maybe::XS

our @EXPORT    = qw/ column_info_from_type /;
our @EXPORT_OK = @EXPORT;

sub column_info_from_type {
    my ($type) = @_;

    my $name    = $type->name;
    my $methods = $type->my_methods;

    if ( $type->is_anon && $type->has_parent ) {
        $name    = $type->parent->name;
        $methods = $type->parent->my_methods;
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

    if ( $name eq 'Maybe' ) {
        return (
            is_nullable => 1,
            column_info_from_type( $type->type_parameter )
        );
    }

    if ( $name eq 'Str' ) {
        return ( data_type => 'text', is_numeric => 0 );
    }

    if ( $name eq 'Int' ) {
        return ( data_type => 'integer', is_numeric => 1 );
    }


    die sprintf('Unsupported type: %s', ref $type);

}

1;
