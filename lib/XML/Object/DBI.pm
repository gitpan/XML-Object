package XOE::BadArrayRef;
use base qw(XOE);

sub new {
    my ($class, $reftype) = @_;
    $reftype = '' unless (defined $reftype);
    my $msg = "invalid array arg: expected ARRAY ref, got: $reftype";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadConnect;
use base qw(XOE);

sub new {
    my ($class, $errstr) = @_;
    my $msg = "can't establish DB connection: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadDo;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't do SQL: path: $path sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadExecute;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't execute SQL: path: $path sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadFetch;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't process statement: path: $path sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadHashRef;
use base qw(XOE);

sub new {
    my ($class, $reftype) = @_;
    $reftype = '' unless (defined $reftype);
    my $msg = "invalid hash arg: expected HASH ref, got: $reftype";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadPrepare;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't prepare SQL: path: $path sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadSQLPath;
use base qw(XOE);

sub new {
    my ($class, $msg) = @_;
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XML::Object::DBI;

use strict;
use warnings;
use base qw(XML::Object);
use Util qw(arrayref hashref ltrim rtrim readfile);
use DBI;

use constant ARRAY	=> 0;
use constant HASH	=> 1;
use constant ITER	=> 2;
use constant COLUMNS	=> 4; # synonyms

our $VERSION = '0.02';

# use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Terse = 1;

sub new {
    my ($class, $config_file, %xmloptions) = @_;
    # specifically: an empty password should become an empty string
    my $self = $class->SUPER::new($config_file, SuppressEmpty => '', %xmloptions);
    my $dsn = $self->test('dsn') || $self->test('datasource') || $self->test('data_source');
    my $user = $self->test('user') || $self->test('username');
    my $pass = $self->test('password');

    # under ODBC neither username nor password are needed;
    $self->dbh($dsn, $user, $pass) if (defined $dsn);

    return $self;
}

# tidy up database handle when this object is destroyed
sub DESTROY {
    my $self = shift;
    my $dbh = $self->dbh();
    $dbh->disconnect() if (defined $dbh); # may have thrown an exception beforei initializing dbh 
}

sub debug {
    my ($self, $message) = @_;
    print STDERR $message, $/;
}

sub dbh {
    my ($self, $dsn, $user, $pass) = @_;
    if ($dsn) {
	my $dbh;
	$pass = '' unless (defined $pass);
	$user = '' unless (defined $user);
	throw XOE::BadConnect($DBI::errstr) unless 
	    ($dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0, AutoCommit => 1 }));
	return $self->{_XML_OBJECT_}->{DBH} = $dbh;
    } else {
	return $self->{_XML_OBJECT_}->{DBH};
    }
}

sub hash2array {
    my ($self, $columns, $hash) = @_;
    throw XOE::BadArrayRef (ref $columns) unless (arrayref $columns);
    throw XOE::BadHashRef (ref $hash) unless (hashref $hash);
    my $array = [];
    local $_;
    push @$array, $hash->{$columns->[$_]} for (0 .. $#$columns);
    return $array;
}

sub array2hash {
    my ($self, $columns, $array) = @_;
    throw XOE::BadArrayRef(ref $columns) unless (arrayref $columns);
    throw XOE::BadArrayRef(ref $array) unless (arrayref $array);
    my $hash = {};
    local $_;
    $hash->{$columns->[$_]} = $array->[$_] for (0 .. $#$columns); 
    return $hash;
}

#############################################

# get is separated so that it can be invoked with an explicit key, as
# well as automatically according to the caller's name

# FIXME: args is now a HASH ref or an ARRAY ref and any arguments before
# it are used to key into the configuration data structure in the standard way

sub caller_getArray {
    my $self = shift;
    return $self->get(ARRAY, $self->grandparent, @_);
}

sub caller_getXArray {
    my $self = shift;
    return $self->get(ARRAY | COLUMNS, $self->grandparent, @_);
}

sub caller_getArrayIter {
    my $self = shift;
    return $self->get(ARRAY | ITER, $self->grandparent, @_);
}

sub caller_getHash {
    my $self = shift;
    return $self->get(HASH, $self->grandparent, @_);
}

sub caller_getXHash {
    my $self = shift;
    return $self->get(HASH | COLUMNS, $self->grandparent, @_);
}

sub caller_getHashIter {
    my $self = shift;
    return $self->get(HASH | ITER, $self->grandparent, @_);
}

#############################################

sub getArray {
    my $self = shift;
    return $self->get(ARRAY, $self->parent, @_);
}

sub getXArray {
    my $self = shift;
    return $self->get(ARRAY | COLUMNS, $self->parent, @_);
}

sub getArrayIter {
    my $self = shift;
    return $self->get(ARRAY | ITER, $self->parent, @_);
}

sub getHash {
    my $self = shift;
    return $self->get(HASH, $self->parent, @_);
}

sub getXHash {
    my $self = shift;
    return $self->get(HASH | COLUMNS, $self->parent, @_);
}

sub getHashIter {
    my $self = shift;
    return $self->get(HASH | ITER, $self->parent, @_);
}

#############################################

sub key_getArray {
    my $self = shift;
    return $self->get(ARRAY, @_);
}

sub key_getXArray {
    my $self = shift;
    return $self->get(ARRAY | COLUMNS, @_);
}

sub key_getArrayIter {
    my $self = shift;
    return $self->get(ARRAY | ITER, @_);
}

sub key_getHash {
    my $self = shift;
    return $self->get(HASH, @_);
}

sub key_getXHash {
    my $self = shift;
    return $self->get(HASH | COLUMNS, @_);
}

sub key_getHashIter {
    my $self = shift;
    return $self->get(HASH | ITER, @_);
}

#############################################

# args: ($self, $mode, @path, $args_array_or_hash_ref)

# where $mode is a conjunction of:

# 0 => ARRAY
# 1 => HASH
# 2 => SUB
# 4 => COLUMNS

# if a getIter sub is called in list context the iterator and columns are returned
# otherwise just the iterator is returned. To get columns when an iterator is not
# being used, use getXArray or getXHash

sub get {
    my $self = shift;
    my $mode = shift;
    my $args = ref $_[-1] ? pop : undef;
    my @path = @_;
    my $path = join '/', @path;
    my ($template, $debug);
    my $get = $self->key_demand(@path, 'get');

    if (ref $get) {
	$debug = $get->{debug};
	if (exists $get->{path}) {
	    my $path = $get->{path};
	    my $fatal = sub { my $errmsg = shift; throw XOE::BadSQLPath ($errmsg) };
	    $template = readfile ($path, DIE => $fatal); # throw an exception if an error occurs
	} else {
	    $template = $get->{content};
	}
    } else {
        $template = $get;
    }

    my $want_columns = $mode & COLUMNS;
    # squashed buglet: don't check for want_array as its value is 0
    my $want_hash = $mode & HASH;
    my $want_sub = $mode & ITER;

    # don't *assume* it's a format as this means percentage signs have to be doubled
    # even in cases where no additional args are being passed

    my $sql;

    if (arrayref $args) {
	$sql = (scalar @$args) ? sprintf ($template, @$args) : $template;
    } elsif (hashref $args) {
	$sql = $template;
	for my $key (keys %$args) {
	    my $value = $args->{$key};
	    $sql =~ s/\%$key\b/$value/g;
	}
    } else {
	$sql = $template;
    }

    $sql = ltrim $sql;
    $sql = rtrim $sql;

    $self->debug("$path: $sql") if ($debug);

    my $dbh = $self->dbh();
    my $sth = $dbh->prepare($sql) || throw XOE::BadPrepare($path, $sql, $dbh->errstr);
    
    $sth->execute() || throw XOE::BadExecute ($path, $sql, $dbh->errstr);

    # squashed MySQL bug: the names ARRAY ref was being undef'd by fetchall_arrayref()
    # so grab them while stocks last

    my $columns = $sth->{NAME};

    if ($want_sub) {
	my $sub;
	if ($want_hash) { # hash sub
	    $sub = sub {
		my $hash_ref = $sth->fetchrow_hashref();
		unless ($hash_ref) {
		    throw XOE::BadFetch ($sth->err) if ($sth->err);
		    return; # return an empty list so that while (@row = &$sub) evaluates to false
		}
		return wantarray ? %$hash_ref : { %$hash_ref }; # DBI reuses the same ref
	    };
	} else { # array sub
	    $sub = sub {
		my $array_ref = $sth->fetchrow_arrayref();
		unless ($array_ref) {
		    throw XOE::BadFetch ($sth->err) if ($sth->err);
		    return; # return an empty list so that while (@row = &$sub) evaluates to false
		}
		return wantarray ? @$array_ref : [ @$array_ref ]; # DBI reuses the same ref
	    };
	}
	# note: return of columns for iterator usage depends entirely on the
        # WANT context: $want_columns is ignored	
	return wantarray ? ($sub, $columns) : $sub;
    } else {
	if ($want_hash) { # hashes
	    my $hash_refs = $sth->fetchall_arrayref({});
	    throw XOE::BadFetch ($path, $sql, $sth->err) if ($sth->err);
	    if ($want_columns) {
		return wantarray ? ($columns, @$hash_refs) : [ $columns, @$hash_refs ]; # DBI reuses the same ref
	    } else {
		return wantarray ? @$hash_refs : [ @$hash_refs ]; # DBI reuses the same ref
	    }
	} else { # arrays
	    my $array_ref = $sth->fetchall_arrayref();
	    throw XOE::BadFetch ($path, $sql, $sth->err) if ($sth->err);
	    if ($want_columns) {
		return wantarray ? ($columns, @$array_ref) : [ $columns, @$array_ref ];
	    } else {
		return wantarray ? @$array_ref : [ @$array_ref ];
	    }
	}
    }
}

#############################################

sub set {
    my $self = shift;
    return $self->_set(0, $self->parent, @_);
}

sub setIter {
    my $self = shift;
    return $self->_set(1, $self->parent, @_);
}

sub key_set {
    my $self = shift;
    return $self->_set(0, @_);
}

sub key_setIter {
    my $self = shift;
    return $self->_set(1, @_);
}

sub caller_set {
    my $self = shift;
    return $self->_set(0, $self->grandparent, @_);
}

sub caller_setIter {
    my $self = shift;
    return $self->_set(1, $self->grandparent, @_);
}

sub _set {
    my $self = shift;
    my $mode = shift;
    my $ref = ref $_[-1] ? pop : undef;
    my @path = @_;
    my $path = join '/', @path;
    my $set = $self->key_demand(@path, 'set');
    my ($template, $debug);

    if (ref $set) {
	$debug = $set->{debug};
	if (exists $set->{path}) {
	    my $path = $set->{path};
	    my $fatal = sub { my $errmsg = shift; throw XOE::BadSQLPath ($errmsg) };
	    $template = readfile ($path, DIE => $fatal); # throw an exception if an error occurs
	} else {
	    $template = $set->{content};
	}
    } else {
        $template = $set;
    }

    # don't *assume* it's a format as this means percentage signs have to be doubled
    # even in cases where no additional args are being passed

    my $transform_sql = sub {
	my $args = shift;
	my $sql;
	if (arrayref $args) {
	    $sql = (scalar @$args) ? sprintf ($template, @$args) : $template;
	} elsif (hashref $args) {
	    $sql = $template;
	    for my $key (keys %$args) {
		my $value = $args->{$key};
		$sql =~ s/\%$key\b/$value/g;
	    }
	} else {
	    $sql = $template;
	}

	$sql = ltrim $sql;
	$sql = rtrim $sql;

	$self->debug("$path: $sql") if ($debug);

	return $sql;
    };

    my $dbh = $self->dbh();
    
    # modes: 0 => immediate, 1 => lazy

    if ($mode == 0) { # array
	my $sql = $transform_sql->($ref);
	my $rows_affected = $dbh->do($sql) || throw XOE::BadDo($path, $sql, $dbh->errstr);
	return $rows_affected;
    } elsif ($mode == 1) { # mutator sub
	return sub {
	    my $bind = ($_[-1]) ? ($_[-1]) : $ref; # override the default args with new args if supplied
	    my $sql = $transform_sql->($bind);
	    my $rows_affected = $dbh->do($sql) || throw XOE::BadDo($path, $sql, $dbh->errstr);
	    return $rows_affected;
	};
    }
}

1;

# __END__

=head1 NAME

    XML::Object::DBI - Methodical DBI Abstraction

=head1 SYNOPSIS

=head2 perl

    package Foo;

    use base qw(XML::Object::DBI);

    sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	# ...
    }

    sub foo {
	my $self = shift;

	# simple API for data source accessors
	for my $hashref ($self->getHash()) {
	    $self->do_something_with($hashref);
	}
    }

    sub bar {
	my $self = shift;

	# positional sprintf-like args
	for my $hashref ($self->getHash([ 'foo', 'bar' ])) {
	    $self->do_something_with($hashref);
	}
    }

    sub baz {
	my $self = shift;

	my $mutator = $self->setIter(); # similar API for mutators 

	# named template-style args
	for my $arrayref ($self->getArray({ 'alpha' => 'beta', 'gamma' => 'vlissides'})) {
	    $mutator->([ $arrayref->{foo}, $arrayref->{bar} ]);
	}
    }

=head2 XML

    <config>
	<new>
	    <dsn>dbi:Pg:dbname=whatever;host=wherever</dsn>
	    <user>foo</user>
	    <password>bar</password>
	</new>
	<foo>
	    <!-- no args -->
	    <get>SELECT * FROM foo WHERE bar = 'baz';</get>
	</foo>
	<bar>
	    <!-- positional -->
	    <get>SELECT * FROM bar WHERE %s = '%s';</get>
	</bar>
	<baz>
	    <!-- named -->
	    <get>SELECT * FROM baz WHERE %alpha = '%beta';</get>
	    <!-- SQL can be inline or external -->
	    <set path="example.sql" />
	</baz>

	<alpha>
    </config>

=head2 example.sql

    UPDATE baz SET foo = 'bar' WHERE %s = %d;

=head1 DESCRIPTION

    XML::Object::DBI is designed to make it easy:
    
	a) to work smoothly and conveniently with SQL without getting
	   tangled in DBI duct tape
	b) to move SQL out of Perl and into XML or SQL files

    XML::Object::DBI adds get*() and set*() methods to the base XML::Object class.

    These provide a DWIMish interface to the usual relational accessors
    and mutators.

    In addition, various utility functions and exceptions are provided.

=head1 METHODS

=head2 new

=head3 usage

    my $dbi = XML::Object::DBI->new($config_file, %optional_xml_simple_options);

=head3 description

Constructs a new XML::Object::DBI object.

Takes the path to a configuration file as an argument, and optionally a HASH of args
to be passed to XML::Simple's C<XMLin()> method - which is used to convert the specified
XML into the object's configuration HASH/ARRAY ref.

Typically this method is not called directly, but rather invoked on the superclass
by the user-supplied subclass of XML::Object::DBI. However, there are circumstances
under which a direct invocation is preferable: for instance, the manipulation of
multiple data sources can easily be achieved through aggregation:

    package Migrator;

    use XML::Object::DBI;

    sub new {
	my class = shift;
	my $self = {};
	$self->{SOURCE} = XML::Object::DBI->new($source_config);
	$self->{DESTINATION} = XML::Object::DBI->new($destination_config);
	bless $self, ref $class || $class;
    }

    sub migrate {
	my ($self, $arg1, $arg2) = @_;
	my $source = $self->source();
	my $destination = $self->destination();
	my $iter = $source->getHashIter([ $arg1, $arg2 ]);
	my $row;

	while ($row = &$iter) {
	    $destination->set({ foo => $row->{foo}, bar => $row->{bar} });
	}
    }

For subclasses of XML::Object::DBI, the constructor can be invoked via the
C<SUPER()> builtin:

    use base qw(XML::Object::DBI);

    sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	# ... 
    }

XML::Object::DBI::new returns a blessed HASH ref whose members
are stored under the key '_XML_OBJECT_' e.g.

    bless { _XML_OBJECT_ => ... }, 'XML::Object::DBI' 

Subclasses will need to bear this in mind if adding new members.

The XML file whose path is specified by $config_file can define
a data source and optionally a username and password in its
<new> ... </new> section.

e.g.

    <config>
	<new>
	    <dsn>dbi:Pg:dbname=whatever;host=wherever</dsn>
	    <user>foo</user>
	    <pass>bar</pass>
	</new>
	...
    </config>

The contents of the <dsn> ... </dsn> tag should be a valid DBI data source
name. See the DBI docs for more info. Valid synonyms are:

    <datasource> ... </datasource>

and:

    <data_source> ... </data_source>

The username and password tags are both optional, but should be empty strings where the
connection requires it:

    <new>
	<data_source>dbi:ODBC:FMPro</data_source>
	<username></username>
	<password></password>
    </new>

Valid synonym for user:

    <username> .. </username>

Valid synonym for password:

    <pass> .. </pass>

If these connection details are not provided in the XML, the C<dbh()> method
will need to be called manually before using the object's accessors/mutators:

    my $dbi = XML::Object::DBI->new($config_file);
    $dbi->dbh($dsn, $user, $password);
    # ...

By default, the top-level tag - <config> .. </config> in the example
above - is not of any significance, although any attributes defined
for it will end up as top-level keys in the configuration HASH:

    <foo bar="baz">
	...
    </foo>

XML::Simpl-ifies to:

    {
	bar => baz,
	...
    }

=head2 getArray

=head3 usage

    my $list_of_arrayrefs = $self->getArray(...);
    my @list_of_arrayrefs = $self->getArray(...);

=head3 description

Evaluates the SQL (typically a SELECT statement) defined under the element
name corresponding to the name of the current function, and returns the results as a
list of ARRAY refs in list context or a reference to a list of ARRAY refs in scalar
context. Specify debug="1" (or some such value of debug that is non-false) to display
the executed SQL using the object's C<debug()> method (which, by default, prints to STDERR).

e.g. 

=head4 XML

    <config>
	<foo>
	    <get debug="1">
		SELECT * FROM wherever;
	    </get>
	</foo>
    </config>

=head4 perl

    sub foo {
	my $self = shift;
	my @list_of_arrayrefs = $self->getArray();
	# ...
    }

As an alternative to inlined SQL, the path to an external SQL file can be specified using
the path attribute:

    <config>
	<foo>
	    <get path="foo.sql" />
	</foo>
    </config>

Arguments to all the get* and set* methods are processed in the same manner as args
to C<demand()>, C<test()> &c. in XML::Object. i.e. a data structure can be passed as the
configuration 'context':

    sub init {
	my $self = shift;
	my $init = $self->demand(); # get the init data structure

	# ignore  
	try {
	    # e.g. DROP TABLE whatever;
	    $self->set($init, 'drop');
	} catch XOE::BadDo with {
	    # ignore error if table doesn't exist 
	}

	$self->set($init, 'create');

	my $insert1 = $self->set($init, 'insert1');
	my $insert2 = $self->set($init, 'insert2');

	printf "rows affected: %d%s", $insert1 + $insert2, $/;
    }

Alternatively (or in addition) a 'path' into the configuration data structure
can be supplied either relative to the current path (determined by the name of
the current sub for the 'standard' accessors and mutators) or absolutely (for
key_get* and key_set*). Note that: however the path is derived, 'get' or 'set'
are always appended to the path expression:

    sub example1 {
	my $self = shift;
	# SQL is looked up under $self->config()->{example1}->{foo}->{bar}->{baz}->{get}
	my $arrayrefs = $self->getArray('foo', 'bar', 'baz');
    }

    sub example2 {
	my $self = shift;
	# SQL is looked up under $self->config()->{foo}->{bar}->{baz}->{get}
	my @arrayrefs = $self->key_getArray('foo', 'bar', 'baz');
    }

An ARRAY ref or HASH ref can be supplied as the final argument to all accessors
and mutators. The mechanism by which these arguments are bound into the generated SQL
are described in the C<set()> documentation below.

=head2 getXArray

=head3 usage

    my $list_of_arrayrefs = $self->getXArray(...);
    my ($columns, @list_of_arrayrefs) = $self->getXArray(...);

=head3 description

This 'enhanced' (think X for eXtra) getArray() prepends an ARRAY ref containing
the names of the fields/columns of the result set.

e.g.

    my ($columns, @arrayrefs) = $self->getXArray();

	# or

    my $get = $self->getXArray();
    my $columns = shift @$get;
    whatever($_) for (@$get);

=head2 getArrayIter

=head3 usage

    my $iter = $self->getArrayIter(...);
    my ($iter, $columns) = $self->getArrayIter(...);

=head3 description

Returns a closure that gives 1-row-at-a-time access to the data
source (in the form of an ARRAY ref or list). The iterator continues
to return true (in scalar or list context) until the data source is
exhausted:

    my $iter = $self->getArrayIter(...);
    my ($row, @row);

    while ($row = &$iter) { ... } # ARRAY ref

	# or

    while (@row = &$iter) { ... } # list

If the call to C<getArrayIter()> is made in list context,
an ARRAY ref representing the names of the columns of
the query's result set is returned as the second argument:

    my ($iter, $columns) = $self->getArrayIter(...);

=head2 getHash

=head3 usage

    my $list_of_hashrefs = $self->getHash(...);
    my @list_of_hashrefs = $self->getHash(...);

=head3 description

Returns a list of HASH refs or a reference to a list of HASH refs
according to context. Usage is otherwise the same as C<getArray()>.

=head2 getXHash

=head3 usage

    my $list_of_hashrefs = $self->getXHash(...);
    my @list_of_hashrefs = $self->getXHash(...);

=head3 description

Returns a list of HASH refs or a reference to a list of HASH refs
with an additional columns ARRAY ref (representing the fields of
the query's result set) as the first item of the list:

    my ($columns, @hashrefs) = $self->getXHash(...);

Usage is otherwise the same as C<getXArray()>.

=head2 getHashIter

=head3 usage

    my $iter = $self->getHashIter(...);

	# or

    my ($iter, $columns) = $self->getHashIter(...);

=head3 description

Returns a closure that gives 1-row-at-a-time access to the data
source (in the form of a HASH ref or hash). The iterator continues
to return true (in scalar or list context) until the data source is
exhausted:

    my ($iter, $columns) = $self->getHashIter(...);

Usage is otherwise the same as C<getArrayIter()>.

=head2 caller_getArray

=head2 caller_getXArray

=head2 caller_getArrayIter

=head2 caller_getHash

=head2 caller_getXHash

=head2 caller_getHashIter

=head2 key_getArray

=head2 key_getXArray

=head2 key_getArrayIter

=head2 key_getHash

=head2 key_getXHash

=head2 key_getHashIter

=head3 description

These methods provide alternative interfaces to the C<get()> family of methods.

The caller_* methods use the name of the *caller* of the current function
(rather than the name of the current function itself) as the root of the
path into the configuration data structure.

The key_* methods allow an explicit path into the configuration data
structure to be specified rather than one that is determined by the call stack.

See XML::Object::key_* and XML::Object::caller_* for more details.

=head2 set

=head3 usage

    sub example {
	my $self = shift;


	my $rows_affected = $self->set(@optional_path, $optional_array_or_hash_ref);

	    # i.e.

	$self->set();

	    # or

	$self->set([ $arg1, $arg2 ]);

	    # or

	$self->set({ arg1 => $arg1, arg2 => $arg2 });

	    # or

	$self->set('foo', 1, 'bar');

	    # or

	$self->set('foo', 1, 'bar', { arg1 => $arg1, arg2 => $arg2 });
    }

=head3 XML

    <config>
	<example>
	    <set>
		UPDATE foo SET bar = %arg1 WHERE baz = %arg2;
	    </set>
	</example>

	<!-- or -->

	<example>
	    <set>
		INSERT INTO foo (bar, baz) VALUES ('%s', %d);
	    </set>
	</example>
    </config>

=head3 description

C<set()> provides a simple API for the implementation of database
operations that 'mutate' rather than 'access' the data source.
Typically, this refers to: INSERT, UPDATE and DELETE.

If an ARRAY ref of args is passed as the last argument to C<set()>,
it is processed the same way as the get* methods:
i.e. each argument is C<sprintf()>'d into the SQL (whether external
or inline) - which is taken to be a printf-style template:

    <config>
	<example>
	    <set debug="1">DELETE FROM foo where %s = '%s';</set>
	</example>
    </config>

    sub example {
	my $self = shift;
	$self->set([ 'bar', 'baz' ]);
    }

- would result in the following query being performed and (thanks to
the debug="1") printed to STDERR:

    DELETE FROM foo WHERE bar = 'baz';

If passed a HASH ref as the last argument, variable names (formed
by prepending a '%' to the hashtable keys) are replaced with their
corresponding hashtable values: thus

    <config>
	<example>
	    <set debug="1">DELETE FROM foo WHERE %bar = '%baz';</set>
	</example>
    </config>

    sub example {
	my $self = shift;
	$self->set({ bar => 'fly', baz => 'luhrmann' ]);
    }

- would result in:

    DELETE FROM foo WHERE fly = 'luhrmann';

All versions of set return an integer representing the number of rows
affected by the operation, or -1 if the number is not known.

This number will always evaluate to true in a boolean context, even though
its arithmentic value may be equivalent to 0 (i.e. 0E0). See the DBI
docs for more details.

Because get* and set* use XML::Object's C<key_demand()> to locate their
'set' and 'get' sections, the @optional_path part of both these families of methods
can supply their own context. e.g. :

    sub example {
	my $self = shift;
	my $cfg = { set => { path => 'wherever.sql' } };
	my $rows_affected = $self->key_set($cfg, [ 'foo', 'bar' ]);
    }

=head2 setIter

=head3 usage

    sub example {
	my $accessor = $self->getHashIter(...);
	my $mutator = $self->setIter(...);
	while ($row = &$get) {
	    $mutator->({ alpha => $row->{alpha}, beta => $row->{beta} }); 
	}
    }

=head3 description

Returns a closure that can be used to perform multiple mutations of a data source.
Each invocation of the closure performs the operation specified in the inline or
external SQL; any arguments passed to the closure are interpolated into the SQL in
accordance with the ARRAY ref and HASH ref conventions outlined in the C<set()>
documentation above.

Note that: arguments passed to C<setIter()> are treated as default bindings that can optionally
be overridden by arguments passed to the iterator itself. e.g:

    my $default = $self->setIter([ 'foo' , 'bar' ]);
    # foo and bar bind into the SQL by default 
    
    &$default;
    # use the default bindings 

    $default->([ 'alpha', 'beta' ]);
    # override the bindings for this call only

=head2 caller_set

=head2 caller_setIter

=head2 key_set

=head2 key_setIter

=head3 description

These methods provide alternative interfaces to the C<set()> family of methods.

The caller_* methods use the name of the *caller* of the current function
(rather than the name of the current function itself) as the root
into the configuration data structure.

The key_* methods allow an explicit path into the configuration data
structure to be specified rather than one that is determined by the call stack.

See XML::Object::key_* and XML::Object::caller_* for more details.

=head2 dbh

=head3 usage

    my $dbh = $self->dbh();

	# or

    $self->dbh($dsn)
   
	# or

    $self->dbh($dsn, $user)

	# or

    $self->dbh($dsn, $user, $password)

=head3 description

When called with no arguments C<dbh()> returns the DBI database handle.

If passed one or more arguments, those values are assigned as the object's
data source name, username and password respectively.

=head2 array2hash

=head3 usage

    my $array = $self->array2hash($columns, $hash);

=head3 description

Converts an ARRAY ref into an a HASH ref using the key provided by the $columns
ARRAY ref to attach keys to the supplied values.

This, in conjunction with C<hash2array()>, facilitates interchange between the HASH
and ARRAY ref types returned by the various accessors.

=head2 hash2array

=head3 usage

    my $array = $self->hash2array($columns, $hash);

=head3 description

Converts a HASH ref into an ARRAY ref using the key provided by the $columns
ARRAY ref to order the fields.

This, in conjunction with C<array2hash()>, facilitates interchange between the HASH
and ARRAY ref types returned by the various accessors.

=head1 EXCEPTIONS

=head2 XOE::BadArrayRef

Thrown if an ARRAY ref argument is expected but not supplied.

=head2 XOE::BadConnect

Thrown if the initial DBI connection fails.

=head2 XOE::BadDo

Thrown if an error occurs while DBI->do() is performed on the SQL supplied to the
C<set()> and C<setIter()> methods.

=head2 XOE::BadExecute

Thrown if the DBI $sth->execute method fails.

=head2 XOE::BadFetch

Thrown if a retrieve operation on a DBI statement handle fails.

=head2 XOE::BadHashRef

Thrown if a HASH ref argument is expected but not supplied.

=head2 XOE::BadPrepare

Thrown if the DBI $sth->prepare method fails.

=head2 XOE::BadSQLPath

Thrown if the <get path="external.sql">...</get> usage refers to a SQL file that can't be read.

=head2 EXPORT

    None by default.

=head1 SEE ALSO

    XML::Object, XML::Simple

=head1 AUTHOR

    chocolateboy <chocolate.boy@email.com>

=head1 COPYRIGHT AND LICENSE

    Copyright 2003 by chocolateboy

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself. 

=cut
