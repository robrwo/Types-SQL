package Types::SQL::Util;

use strictures;

use Exporter qw/ import /;

use PerlX::Maybe;

# RECOMMEND PREREQ: PerlX::Maybe::XS

our @EXPORT    = qw/ column_info_from_type /;
our @EXPORT_OK = @EXPORT;

sub column_info_from_type {
    my ($type) = @_;

    my $name    = $type->name;
    my $methods = $type->my_methods;

    if ( $name eq '__ANON__' ) {
        $name    = $type->parent->name;
        $methods = $type->parent->my_methods;
    }

    if ( $methods && $methods->{dbic_column_info} ) {
        return $methods->{dbic_column_info}->($type);
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

    if ( $name eq 'Serial' ) {    #
        return (
            data_type         => 'integer',
            is_auto_increment => 1,
            is_numeric        => 1,
            is_nullable       => 0,
            maybe size        => $type->type_parameter
        );
    }

}

1;
