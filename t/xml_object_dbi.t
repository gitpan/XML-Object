#!perl

package XML::Object::DBI::Test;

use strict;
use warnings;

use base qw(XML::Object::DBI);
# annoying bug: XML::Object needs to be loaded before Test::More
# because Test::More exports set()
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
    } catch XOE::BadSet with {
	# and ignore it
    };

    $self->key_set($init, 'create');

    my $insert1 = $self->key_set($init, 'insert1');
    my $insert2 = $self->key_set($init, 'insert2');

    is ($insert1 + $insert2, 2, 'inserts: rows affected == 2');

    my $get = $self->get->arrayrefs();
    my $want =  [
	[ 'alpha', 'beta' ],
	[ 'gamma', 'vlissides' ]
    ];

    is_deeply ($get, $want, 'init');
}

####################### scalar context ##########################

sub test_s_get_scalar {
    my $self = shift;
    my $get = $self->get()->scalar();
    my $want = 'beta';
    is_deeply ($get, $want, 'scalar: $self->get()->scalar()');
}

sub test_s_get_scalars {
    my $self = shift;
    my $get = $self->get()->scalars();
    my $want = [ 'alpha', 'gamma' ];
    is_deeply ($get, $want, 'scalar: $self->get()->scalars()');
}

sub test_s_get_fields {
    my $self = shift;
    my $get = $self->get()->fields();
    my $want = ['lhs', 'rhs'];
    is_deeply ($get, $want, 'scalar: $self->get()->fields()');
}

sub test_s_get_arrayref {
    my $self = shift;
    my $get = $self->get();
    my @get = ();
    my $arrayref;
    push (@get, $arrayref) while ($arrayref = $get->arrayref);
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'scalar: $self->get()->arrayref');
}

sub test_s_get_arrayrefs {
    my $self = shift;
    my $get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply ($get, $want, 'scalar: $self->get()->arrayrefs()');
}

sub test_s_get_hashref {
    my $self = shift;
    my $get = $self->get();
    my @get = ();
    my $hashref;
    push (@get, $hashref) while ($hashref = $get->hashref);
    my $want = [ 
	{ lhs => 'alpha', rhs => 'beta' },
	{ lhs => 'gamma', rhs => 'vlissides' }
    ];
    is_deeply (\@get, $want, 'scalar: $self->get()->hashref()');
}

sub test_s_get_hashrefs {
    my $self = shift;
    my $get = $self->get()->hashrefs();
    my $want = [ 
	{ lhs => 'alpha', rhs => 'beta' },
	{ lhs => 'gamma', rhs => 'vlissides' }
    ];
    is_deeply ($get, $want, 'scalar: $self->get()->hashrefs()');
}

######################## list context ##########################

sub test_l_get_and_fields {
    my $self = shift;
    my ($get, $fields) = $self->get();
    my $want = [ 'lhs', 'rhs' ];
    is_deeply ($fields, $want, 'list: ($get, $fields) = $self->get()');
}

sub test_l_get_fields {
    my $self = shift;
    my $get = $self->get();
    my @fields = $get->fields();
    my $want = [ 'lhs', 'rhs' ];
    is_deeply (\@fields, $want, 'list: $self->get()->fields()');
}

sub test_l_get_scalar {
    my $self = shift;
    my @get = $self->get()->scalar();
    my $want = [ 'rhs', 'beta' ];
    is_deeply (\@get, $want, 'list: $self->get()->scalar()');
}

sub test_l_get_scalars {
    my $self = shift;
    my @get = $self->get()->scalars();
    my $want = [ 'alpha', 'gamma' ];
    is_deeply (\@get, $want, 'list: $self->get()->scalars()');
}

sub test_l_get_arrayref {
    my $self = shift;
    my $get = $self->get();
    my @get = ();
    my @arrayref;
    push (@get, [ @arrayref ]) while (@arrayref = $get->arrayref);
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'list: $self->get()->arrayref');
}

sub test_l_get_arrayrefs {
    my $self = shift;
    my @get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'vlissides'] ];
    is_deeply (\@get, $want, 'list: $self->get()->arrayrefs()');
}

sub test_l_get_hashref {
    my $self = shift;
    my $get = $self->get();
    my @get = ();
    my %hashref;
    push (@get, { %hashref }) while (%hashref = $get->hashref);
    my $want = [ 
	{ lhs => 'alpha', rhs => 'beta' },
	{ lhs => 'gamma', rhs => 'vlissides' }
    ];
    is_deeply (\@get, $want, 'list: $self->get()->hashref()');
}

sub test_l_get_hashrefs {
    my $self = shift;
    my @get = $self->get()->hashrefs();
    my $want = [ 
	{ lhs => 'alpha', rhs => 'beta' },
	{ lhs => 'gamma', rhs => 'vlissides' }
    ];

    is_deeply (\@get, $want, 'list: $self->get()->hashrefs()');
}

############################ misc ##############################

sub test_get_arrayref {
    my $self = shift;
    my $get = $self->get([ 'alpha' ])->arrayref();
    my $want = [ 'alpha', 'beta' ];
    is_deeply ($get, $want, 'scalar: get(ARRAY ref)->arrayref()');
}

sub test_get_hashref {
    my $self = shift;
    my $get = $self->get({ field => 'lhs', value => 'alpha'})->hashref();
    my $want = { lhs => 'alpha', rhs => 'beta' };
    is_deeply ($get, $want, 'scalar: get(HASH ref)->hashrefs()');
}

sub test_set_1 { # args are supplied to set but not to the mutator
    my $self = shift;
    my $set = $self->setIter([ 'delta' ]);
    my $rows_affected = &$set;
    is ($rows_affected, 1, q{set(ARRAY ref): rows affected == 1});
    my $get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'delta'] ];
    is_deeply ($get, $want, 'args are supplied to set() but not to the mutator');
}

sub test_set_2 { # args are supplied to the mutator but not to set
    my $self = shift;
    # bollocks: Test::Deep exports every motherf****in'
    # thang (including set()) by default :-(
    my $set = $self->setIter();
    my $rows_affected = $set->({ lhs => 'foo', rhs => 'bar' });
    is ($rows_affected, 1, q{set(ARRAY ref): rows affected == 1});
    my $get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'delta'], ['foo', 'bar'] ];
    is_deeply ($get, $want, 'args are supplied to the mutator but not to set()');
}

sub test_set_3 { # args are supplied to set but then overridden by the mutator
    my $self = shift;
    # bollocks: Test::Deep exports every motherf****in'
    # thang (including set()) by default :-(
    my $set = $self->setIter({ lhs => 'MY', rhs => 'BAD' });
    my $rows_affected = $set->({ lhs => 'move', rhs => 'zig' });
    is ($rows_affected, 1, q{set(ARRAY ref): rows affected == 1});
    my $get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'delta'], ['foo', 'bar'], ['move', 'zig' ] ];
    is_deeply ($get, $want, 'args are supplied to set() but then overridden by the mutator');
}

sub test_set_4 { # args are supplied to set but then overridden by the mutator
    my $self = shift;
    # bollocks: Test::Deep exports every motherf****in'
    # thang (including set()) by default :-(
    my $rows_affected = XML::Object::DBI::set($self);
    is ($rows_affected, 2, q{set(ARRAY ref): rows affected == 1});
    my $get = $self->get()->arrayrefs();
    my $want = [ ['alpha', 'beta'], ['gamma', 'delta'] ];
    is_deeply ($get, $want, 'vanilla set() no args');
}

1;

package main;

use strict;
use warnings;

use Test::More;
use Error qw(:try);

my $obj = XML::Object::DBI::Test->new ('./xml_object_dbi.xml');
try {
    SKIP: {
	skip 'XOD environment variable(s) not defined (see README)', 27
	    unless (exists $ENV{XOD_DSN});
	$obj->dbh($ENV{XOD_DSN}, $ENV{XOD_USER}, $ENV{XOD_PASS});

	$obj->init();

	$obj->test_s_get_scalar();
	$obj->test_s_get_scalars();
	$obj->test_s_get_fields();
	$obj->test_s_get_arrayref();
	$obj->test_s_get_arrayrefs();
	$obj->test_s_get_hashref();
	$obj->test_s_get_hashrefs();

	$obj->test_l_get_and_fields();
	$obj->test_l_get_fields();
	$obj->test_l_get_scalar();
	$obj->test_l_get_scalars();
	$obj->test_l_get_arrayref();
	$obj->test_l_get_arrayrefs();
	$obj->test_l_get_hashref();
	$obj->test_l_get_hashrefs();

	$obj->test_get_arrayref();
	$obj->test_get_hashref();
	$obj->test_set_1();
	$obj->test_set_2();
	$obj->test_set_3();
	$obj->test_set_4();
    }
} catch Error with {
    my $e = shift;
    printf STDERR "$/class: %s$/msg: %s$/stacktrace: %s",
	ref $e, $e, $e->stacktrace();
};
