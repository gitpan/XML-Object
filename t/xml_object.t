#!perl

package XML::Object::Test;

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    use_ok ('XML::Object');
}

use base qw(XML::Object);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(shift);
    return bless $self, ref $class || $class;
}

sub t_test {
    my $self = shift;
    return $self->test();
}

sub t_demand {
    my $self = shift;
    return $self->demand();
}

sub t_key_test {
    my ($self, $key) = @_;
    return $self->key_test($key);
}

sub t_key_demand {
    my ($self, $key) = @_;
    return $self->key_demand($key);
}

sub t_caller_test1 {
    my ($self, $key) = @_;
    return $self->t_caller_test2();
}

sub t_caller_test2 {
    my ($self, $key) = @_;
    return $self->caller_test();
}

1;

package main;

use strict;
use warnings;
use Test::More;

# we don't actually use the class directly (yet) but may as well test it's loaded ok
# BEGIN { use_ok('XML::Object'); }

my $test = XML::Object::Test->new('./xml_object.xml');
ok ($test, 'subclass constructor');
ok ($test->t_test() eq 'alpha', 'test');
ok ($test->t_demand() eq 'beta', 'demand');
ok ($test->t_key_test('t_test') eq 'alpha', 'key_test');
ok ($test->t_key_demand('t_demand') eq 'beta', 'key_demand');
ok ($test->t_caller_test1() eq 'calling occupants', 'caller_test');
