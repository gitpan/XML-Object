#!perl

package XML::Object::DBI::Test;

use strict;
use warnings;

# annoying bug: XML::Object needs to be loaded before Test::More: why?
use base qw(XML::Object::DBI);
use Test::More tests => 28;
use Error qw(:try);
use Data::Dumper; $Data::Dumper::Terse = $Data::Dumper::Indent = 1;

# TODO: Test::Exception exception tests

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
    use_ok ('XML::Object::DBI', qw(:all));
}

sub init {
    my $self = shift;
    my $init = $self->demand();
    try {
	$self->key_set($init, 'drop');
    } catch XOE::BadDo with {
	# and ignore it
    };
    my $create = $self->key_set($init, 'create');
    my $insert1 = $self->key_set($init, 'insert1');
    my $insert2 = $self->key_set($init, 'insert2');
    is ($insert1 + $insert2, 2, 'inserts: rows affected == 2');
    my $get = $self->getXArray();
    my $want =  [
	[ 'lhs','rhs' ],
	[ 'alpha', 'beta' ],
	[ 'gamma', 'vlissides' ]
    ];
    is_deeply ($get, $want, 'init');
}

# scalar context

sub test_s_getArray {
    my $self = shift;
    my $get = $self->getArray();
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply ($get, $want, 'scalar: getArray');
}

sub test_s_getXArray {
    my $self = shift;
    my $get = $self->getXArray();
    my $want =  [
	[ 'lhs','rhs' ],
	[ 'alpha', 'beta' ],
	[ 'gamma', 'vlissides' ]
    ];
    is_deeply ($get, $want, 'scalar: getXArray');
}

sub test_s_getArrayIter1 {
    my $self = shift;
    my $get = $self->getArrayIter();
    my @get = ();
    my $row;
    push (@get, $row) while ($row = &$get);
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'scalar: getArrayIter');
}

sub test_s_getArrayIter2 {
    my $self = shift;
    my ($get, $columns) = $self->getArrayIter();
    my @get = ($columns);
    my $row;
    push (@get, $row) while ($row = &$get);
    my $want = [ [ 'lhs', 'rhs' ], ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'scalar: getArrayIter (with columns)');
}

sub test_s_getHash {
    my $self = shift;
    my $get = $self->getHash();
    my $want = [
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply ($get, $want, 'scalar: getHash');
}

sub test_s_getXHash {
    my $self = shift;
    my $get = $self->getXHash();
    my $want = [
	[ 'lhs', 'rhs' ],
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply ($get, $want, 'scalar: getXHash');
}

sub test_s_getHashIter1 {
    my $self = shift;
    my $get = $self->getHashIter();
    my @get = ();
    my $row;
    push (@get, $row) while ($row = &$get);
    my $want = [
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'list: getHashIter');
}

sub test_s_getHashIter2 {
    my $self = shift;
    my ($get, $columns) = $self->getHashIter();
    my @get = ($columns);
    my $row;
    push (@get, $row) while ($row = &$get);
    my $want = [
	[ 'lhs', 'rhs' ],
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'list: getHashIter (with columns)');
}

#################################################################

sub test_l_getArray {
    my $self = shift;
    my @get = $self->getArray();
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'list: getArray');
}

sub test_l_getXArray {
    my $self = shift;
    my @get = $self->getXArray();
    my $want =  [
	[ 'lhs','rhs' ],
	[ 'alpha', 'beta' ],
	[ 'gamma', 'vlissides' ]
    ];
    is_deeply (\@get, $want, 'list: getXArray');
}

sub test_l_getArrayIter1 {
    my $self = shift;
    my $get = $self->getArrayIter();
    my @get = ();
    my @row = ();
    push (@get, [ @row ]) while (@row = &$get);
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'scalar: getArrayIter');
}

sub test_l_getArrayIter2 {
    my $self = shift;
    my ($get, $columns) = $self->getArrayIter();
    my @get = ($columns);
    my @row = ();
    push (@get, [ @row ]) while (@row = &$get);
    my $want = [ [ 'lhs', 'rhs' ], ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'scalar: getArrayIter (with columns)');
}

sub test_l_getHash {
    my $self = shift;
    my @get = $self->getHash();
    my $want = [
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'list: getHash');
}

sub test_l_getXHash {
    my $self = shift;
    my @get = $self->getXHash();
    my $want = [
	[ 'lhs', 'rhs' ],
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'scalar: getXHash');
}

sub test_l_getHashIter1 {
    my $self = shift;
    my $get = $self->getHashIter();
    my @get = ();
    my @row = ();
    push (@get, { @row }) while (@row = &$get);
    my $want = [
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'scalar: getHashIter');
}

sub test_l_getHashIter2 {
    my $self = shift;
    my ($get, $columns) = $self->getHashIter();
    my @get = ($columns);
    my @row = ();
    push (@get, { @row }) while (@row = &$get);
    my $want = [
	[ 'lhs', 'rhs' ],
	{ 'lhs' => 'alpha', 'rhs' => 'beta'},
	{ 'lhs' => 'gamma', 'rhs' => 'vlissides'}
    ];
    is_deeply (\@get, $want, 'scalar: getHashIter (with columns)');
}

# misc

sub test_arrayref {
    my $self = shift;
    my $get = $self->getArray([ 'alpha' ]);
    my $want = [ [ 'alpha', 'beta' ] ];
    is_deeply ($get, $want, 'scalar: getArray(ARRAY ref)');
}

sub test_hashref {
    my $self = shift;
    my $get = $self->getHash({ field => 'lhs', value => 'alpha' });
    my $want = [ { lhs => 'alpha', rhs => 'beta' } ];
    is_deeply ($get, $want, 'scalar: getHash(HASH ref)');
}

sub test_set {
    my $self = shift;
    # bollocks: Test::Deep exports every motherf****in'
    # thang (including set()) by default :-(
    my $rows_affected = XML::Object::DBI::set($self, [ 'delta' ]);
    is ($rows_affected, 1, q{set(ARRAY ref): rows affected == 1});
    my $get = $self->getXArray();
    my $want = [ [ 'lhs', 'rhs' ], ['alpha', 'beta'], ['gamma', 'delta'] ];
    is_deeply($get, $want, 'table after set_test');
}

sub test_setIter_args {
    my $self = shift;
    my $set = $self->setIter();
    for my $hash ({ lhs => 'foo', rhs => 'bar' }, { lhs => 'move', rhs => 'zig' }) {
	my $rows_affected = $set->($hash);
	is ($rows_affected, 1, q{setIter(HASH ref): rows affected == 1});
    }
    my $get = $self->getXArray();
    my $want = [ [ 'lhs', 'rhs' ], ['alpha', 'beta'], ['gamma', 'delta'], ['foo', 'bar'],  ['move', 'zig'] ];
    is_deeply($get, $want, 'table after test_setIter_args');
}

sub test_setIter_noargs { # args are supplied to set but not to the mutator
    my $self = shift;
    my $set = $self->setIter([ 'foo', 'move' ]);
    my $rows_affected = &$set;
    is ($rows_affected, 2, q{set(ARRAY ref): rows affected == 2});
    my $get = $self->getXArray();
    my $want = [ [ 'lhs', 'rhs' ], ['alpha', 'beta'], ['gamma', 'delta'] ];
    is_deeply($get, $want, 'table after test_setIter_noargs');
}

1;

package main;

use strict;
use warnings;

use Test::More;

my $obj = XML::Object::DBI::Test->new ('./xml_object_dbi.xml');
use Error;
$Error::Debug = 1;

SKIP: {
    skip 'XOD environment variable(s) not defined', 23 unless (exists $ENV{XOD_DSN});
    $obj->dbh($ENV{XOD_DSN}, $ENV{XOD_USER}, $ENV{XOD_PASS});

    $obj->init();

    $obj->test_s_getArray();
    $obj->test_s_getXArray();
    $obj->test_s_getArrayIter1();
    $obj->test_s_getArrayIter2();
    $obj->test_s_getHash();
    $obj->test_s_getXHash();
    $obj->test_s_getHashIter1();
    $obj->test_s_getHashIter2();

    $obj->test_l_getArray();
    $obj->test_l_getXArray();
    $obj->test_l_getArrayIter1();
    $obj->test_l_getArrayIter2();
    $obj->test_l_getHash();
    $obj->test_l_getXHash();
    $obj->test_l_getHashIter1();
    $obj->test_l_getHashIter2();

    $obj->test_arrayref();
    $obj->test_hashref();
    $obj->test_set();
    $obj->test_setIter_args();
    $obj->test_setIter_noargs();
}
