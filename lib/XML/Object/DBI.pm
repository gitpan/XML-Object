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

package XOE::BadScalarFields;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $fields) = @_;
    my $msg = "scalar(s): invalid number of fields: $fields path: '$path' sql: '$sql'";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadScalarRows;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $rows) = @_;
    my $msg = "scalar: invalid number of rows: $rows path: '$path' sql: '$sql'";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadSet;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't do SQL: path: '$path' sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadTemplate;
use base qw(XOE);

sub new {
    my ($class, $err, $path, $template) = @_;
    my $msg = "${err} path: '$path' template: '$template'";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadExecute;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't execute SQL: path: '$path' sql: '$sql' err: $errstr";
    my $self = $class->SUPER::new($msg);
    bless $self, ref $class || $class;
}

1;

package XOE::BadFetch;
use base qw(XOE);

sub new {
    my ($class, $path, $sql, $errstr) = @_;
    my $msg = "can't process statement: path: '$path' sql: '$sql' err: $errstr";
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
    my $msg = "can't prepare SQL: path: '$path' sql: '$sql' err: $errstr";
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

package XML::Object::DBI::Accessor;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = [ @_ ]; # $fields, $sth, $path, $sql
    bless $self, ref $class || $class;
}

sub hashref {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $hash_ref = $sth->fetchrow_hashref();
    unless ($hash_ref) {
	throw XOE::BadFetch ($sth->err) if ($sth->err);
	return; # return an empty list so that while (@row = &$sub) evaluates to false
    }
    return wantarray ? %$hash_ref : { %$hash_ref }; # DBI reuses the same ref
}

sub hashrefs {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $hash_refs = $sth->fetchall_arrayref({});
    throw XOE::BadFetch ($path, $sql, $sth->err) if ($sth->err);
    # DBI reuses the same ref
    return wantarray ? @$hash_refs : [ @$hash_refs ];
}

sub arrayref {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $array_ref = $sth->fetchrow_arrayref();
    unless ($array_ref) {
	throw XOE::BadFetch ($sth->err) if ($sth->err);
	return; # return an empty list so that while (@row = &$sub) evaluates to false
    }
    return wantarray ? @$array_ref : [ @$array_ref ]; # DBI reuses the same ref
}

sub arrayrefs {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $hash_refs = $sth->fetchall_arrayref();
    throw XOE::BadFetch ($path, $sql, $sth->err) if ($sth->err);
    # DBI reuses the same ref
    return wantarray ? @$hash_refs : [ @$hash_refs ];
}

sub scalar {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $arrayrefs = $self->arrayrefs();
    my $nfields = $#$fields + 1;
    my $nrows = $#$arrayrefs + 1;
    throw XOE::BadScalarFields ($path, $sql, $nfields) unless ($nfields == 1);
    throw XOE::BadScalarRows ($path, $sql, $nrows) unless ($nrows == 1);
    return wantarray ? ($fields->[0], $arrayrefs->[0]->[0]) :  $arrayrefs->[0]->[0]; 
}

sub scalars {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    my $arrayrefs = $self->arrayrefs();
    my $nfields = $#$fields + 1;
    throw XOE::BadScalarFields ($path, $sql, $nfields) unless ($nfields == 1);
    my $scalars = [ map { $_->[0] } @$arrayrefs ];
    # isolated from reused DBI ref by map
    return wantarray ? @$scalars : $scalars;
}

sub fields {
    my $self = shift;
    my ($sth, $fields, $path, $sql) = @$self;
    return wantarray ? @$fields : $fields;
}

1;

package XML::Object::DBI;

use strict;
use warnings;
use base qw(XML::Object);
use Util qw(arrayref hashref ltrim rtrim readfile);
use DBI;

our $VERSION = '0.03';

# use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Terse = 1;

sub new {
    my ($class, $config_file, %xmloptions) = @_;
    # specifically: an empty password should become an empty string
    my $self = $class->SUPER::new($config_file, SuppressEmpty => '', %xmloptions);
    my $dsn = $self->test('dsn') || $self->test('datasource')
       	|| $self->test('data_source');
    my $user = $self->test('user') || $self->test('username');
    my $pass = $self->test('password') || $self->test('pass');

    # under ODBC neither username nor password are needed;
    $self->dbh($dsn, $user, $pass) if (defined $dsn);

    return $self;
}

# tidy up database handle when this object is destroyed
sub DESTROY {
    my $self = shift;
    my $dbh = $self->dbh();
    # may have thrown an exception before initializing dbh 
    $dbh->disconnect() if (defined $dbh);
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
	    ($dbh = DBI->connect($dsn, $user, $pass,
	    { RaiseError => 0, PrintError => 0, AutoCommit => 1 }));
	return $self->{_XML_OBJECT_}->{DBH} = $dbh;
    } else {
	return $self->{_XML_OBJECT_}->{DBH};
    }
}

sub hash2array {
    my ($self, $fields, $hash) = @_;
    throw XOE::BadArrayRef (ref $fields) unless (arrayref $fields);
    throw XOE::BadHashRef (ref $hash) unless (hashref $hash);
    my $array = [];
    push @$array, $hash->{$fields->[$_]} for (0 .. $#$fields);
    return $array;
}

sub array2hash {
    my ($self, $fields, $array) = @_;
    throw XOE::BadArrayRef(ref $fields) unless (arrayref $fields);
    throw XOE::BadArrayRef(ref $array) unless (arrayref $array);
    my $hash = {};
    $hash->{$fields->[$_]} = $array->[$_] for (0 .. $#$fields); 
    return $hash;
}

#############################################

# args: ($self, $optional_configuration, @optional_path, $optional_array_or_hash_ref)

# if get() or key_get is called in list context the accessor and fields are returned
# otherwise just the accessor is returned.

sub get {
    my $self = shift;
    if (((scalar @_) > 1) && (ref $_[0])) {
	my $cfg = shift;
	return $self->key_get($cfg, $self->parent, @_);
    } else {
	return $self->key_get($self->parent, @_);
    }
}

sub key_get {
    my $self = shift;
    my $cfg;

    if (((scalar @_) > 1) && (ref $_[0])) {
	$cfg = shift;
    } else {
	$cfg = $self->config();
    }

    my $args = ref $_[-1] ? pop : undef;
    my @path = @_;
    my $path = join '/', @path;

    my ($template, $debug);
    my $get = $self->key_demand($cfg, @path, 'get');

    if (ref $get) {
	$debug = $get->{debug};
	if (exists $get->{path}) {
	    my $path = $get->{path};
	    my $fatal = sub { my $errmsg = shift; throw XOE::BadSQLPath ($errmsg) };
	    # throw an exception if an error occurs
	    $template = readfile ($path, DIE => $fatal);
	} else {
	    $template = $get->{content};
	}
    } else {
        $template = $get;
    }

    # don't *assume* it's a format as this means percentage signs have to be doubled
    # even in cases where no additional args are being passed

    my $sql;

    if (arrayref $args) {
	local $SIG{__WARN__} = sub { my $err = shift; throw XOE::BadTemplate ($err, $path, $template) };
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

    $sql = ltrim rtrim $sql;

    $self->debug("$path: $sql") if ($debug);

    my $dbh = $self->dbh();
    my $sth = $dbh->prepare($sql) || throw XOE::BadPrepare($path, $sql, $dbh->errstr);
    
    $sth->execute() || throw XOE::BadExecute ($path, $sql, $dbh->errstr);

    # squashed MySQL bug: the names ARRAY ref was being undef'd by fetchall_arrayref()
    # so grab them while stocks last

    my $fields = $sth->{NAME};

    my $accessor = XML::Object::DBI::Accessor->new($sth, $fields, $path, $sql);
    return wantarray ? ($accessor, $fields) : $accessor;
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
	    # throw an exception if an error occurs
	    $template = readfile ($path, DIE => $fatal);
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
	    local $SIG{__WARN__} = sub { my $err = shift; throw XOE::BadTemplate ($err, $path, $template) };
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

	return $sql;
    };

    my $dbh = $self->dbh();
    
    my $sub = sub {
	# override the default args with new args if supplied
	my $bind = ($_[-1]) ? ($_[-1]) : $ref;
	my $sql = $transform_sql->($bind);

	$self->debug("$path: $sql") if ($debug);

	my $rows_affected = $dbh->do($sql)
	    || throw XOE::BadSet($path, $sql, $dbh->errstr);
	return $rows_affected;
    };

    return $mode ? $sub : $sub->();
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

	return $self;
    }

    sub method1 {
	my $self = shift;

	# simple API for data source accessors: no args
	for my $hashref ($self->get()->hashrefs) {
	    $self->do_something_with($hashref);
	}
    }

    sub method2 {
	my $self = shift;

	# positional sprintf-like bindings
	for my $hashref ($self->get([ 'foo', 'bar' ])->hashrefs) {
	    $self->do_something_with($hashref);
	}
    }

    sub method3 {
	my $self = shift;
	my $mutator = $self->setIter(); # similar API for mutators 

	# named template-style bindings
	my $bind = { 'alpha' => 'beta', 'gamma' => 'vlissides'};
	my $get = $self->get($bind);

	# row-at-a-time
	while ($arrayref = $get->arrayref) {
	    $mutator->(...);
	}
    }

    sub method4 {
	my $self = shift;
	my $get = $self->get([ 42 ]);
	my $scalar = $get->scalar();
    }

=head2 XML

    <config>
	<new>
	    <dsn>dbi:Pg:dbname=whatever;host=wherever</dsn>
	    <user>foo</user>
	    <password>bar</password>
	</new>

	<method1>
	    <!-- no args -->
	    <get>SELECT * FROM foo WHERE bar = 'baz';</get>
	</method1>

	<method2>
	    <!-- positional -->
	    <get>SELECT * FROM bar WHERE %s = '%s';</get>
	</method2>

	<method3>
	    <!-- named -->
	    <get>SELECT * FROM baz WHERE %alpha = '%beta';</get>
	    <!-- SQL can be inline or external -->
	    <set path="example.sql" />
	</method3>

	<method4>
	    <!-- single row, single column -->
	    <get>SELECT foo FROM bar WHERE unique_id = %d;</get>
	</method4>

    <config>

=head1 DESCRIPTION

    XML::Object::DBI is designed to make it easy:
    
	a) to work smoothly and conveniently with SQL without getting
	   tangled in DBI duct tape
	b) to move SQL out of Perl and into XML or SQL files

    XML::Object::DBI adds get() and set() methods to the base XML::Object class.

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
	my $get = $source->get([ $arg1, $arg2 ]);
	my $row;

	while ($row = $get->hashref) {
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
name. Valid synonyms are:

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

=head2 get

=head2 key_get

=head3 usage

    my $accessor = $self->get($optional_config, @optional_path, $optional_bindings);
	# or
    my $accessor = $self->key_get($optional_config, @optional_path, $optional_bindings);


    my $scalar = $accessor->scalar(); # single row, single column
    my @scalars = $accessor->scalars(); # single column, list context
    my $scalars = $accessor->scalars(); # single column, scalar context

	# or

    while ($arrayref = $accessor->arrayref) { ... }
	# AKA
    while (@array = $accessor->arrayref) { ... }

	# or

    for my $arrayref ($accessor->arrayrefs) { ... }
	# AKA
    my $array_of_arrayrefs = $accessor->arrayrefs();

	# or

    while ($hashref = $accessor->hashref) { ... }
	# AKA
    while (%hash = $accessor->hashref) { ... }

	# or

    for my $hashref ($accessor->hashrefs) { ... }
	# AKA
    my $array_of_hashrefs = $accessor->hashrefs();

	# or

    my $fields = $accessor->fields();
	# AKA
    my @fields = $accessor->fields();

=head3 description

C<get()> evaluates the SQL (typically a SELECT statement) defined under the element
name corresponding to the name of the current function, and returns a new
XML::Object::DBI::Accessor object as a result. This object implements the methods
outlined above: C<arrayref()>, C<arrayrefs()>, C<hashref()>, C<hashrefs()>,
C<scalar()>, C<scalars()> and C<fields()>.

key_get() works the same, but takes an absolute path instead of deriving it from
the name of the current method. Thus:

    sub foo {
	my $self = shift;
	my $get = $self->get();
    }

is equivalent to:

    sub foo {
	my $self = shift;
	# use 'foo' as key into configuration data structure
	my $get = $self->get($self->self);
    }
	
If debug="1" (or some such value of debug that is non-false) is specified in the XML,
the executed SQL is processed via the XML::Object::DBI::debug() method (which, by
default, prints to STDERR). Subclasses can override this to provide other behaviour.

e.g. 

=head4 XML

    <config>
	<foo>
	    <get debug="1">
		SELECT * FROM wherever;
	    </get>
	</foo>
    </config>

As an alternative to inlined SQL, the path to an external SQL file can be specified using
the path attribute:

    <config>
	<foo>
	    <get path="foo.sql" />
	</foo>
    </config>

Arguments to C<get()>, C<key_get()>, C<set()>, C<key_set()>, C<setIter()> and
C<key_setIter()> are processed in the same manner as args to C<demand()>, C<test()>
&c. in XML::Object. i.e. a data structure can be passed as the configuration 'context':

    sub init {
	my $self = shift;
	my $init = $self->demand(); # get the init data structure

	# ignore  
	try {
	    # e.g. DROP TABLE whatever;
	    $self->set($init, 'drop');
	} catch XOE::BadSet with {
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
key_get and key_set*). Note that: however the path is derived, 'get' or 'set'
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

An ARRAY ref or HASH ref can be supplied as the final argument to all C<get()> and
C<set()> methods. The mechanism by which these arguments are bound into
the generated SQL are described in the C<set()> section below.

An ARRAY or HASH ref is considered to be a collection of
template bindings (either positional or named) if it appears at the end of a parameter 
list containing two or more arguments; conversely, an ARRAY or HASH ref appearing
at the beginning of a parameter list (again: with two or more arguments) is considered to be a
configuration 'context' i.e. the data structure against which lookups are performed.

In the ambiguous case where only one argument is supplied and that argument is a reference,
it is taken to be a collection of template bindings rather than a configuration context.
i.e.

    sub foo {
	my $self = shift;
	my $get = $self->get($hashref);
    }

resolves to:

    sub foo {
	my $self = shift;
	# look up $self->config()->{foo} and perform template substitutions contained in $hashref
	my $get = $self->key_get($self->self, $hashref);
    }

rather than:

    sub foo {
	my $self = shift;
	# look up $hashref->{foo}->{get}
	my $get = $self->key_get($hashref, $self->self);
    }

To perform the latter query, simply write it out as shown with at least one other argument
to provide explicit disambiguation.

In list context, C<get()> and C<key_get()> return an ARRAY ref of the fields associated with
the query - this corresponds to the value returned by the XML::Object::DBI::Accessor::fields()
method:

    sub whatever {
	my $get = $self->get(...);
	my $fields = $get->fields();

	# or

	my ($get, $fields) = $self->get(...);
    }

=head2 set

=head2 key_set

=head3 usage

    sub example {
	my $self = shift;


	my $rows_affected = $self->set($optional_context, @optional_path, $optional_bindings);

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

	    # or

	$self->set($config, 'foo', 1, 'bar', { arg1 => $arg1, arg2 => $arg2 });
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
it is processed the same way as the get* methods: i.e. each argument
is C<sprintf()>'d into the SQL (whether external
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
	$self->set({ bar => 'fly', baz => 'luhrmann' });
    }

- would result in:

    DELETE FROM foo WHERE fly = 'luhrmann';

All invocations of C<set()> and C<key_set()> and of the iterators returned
by C<setIter()> and C<key_setIter()> return an integer representing the
number of rows affected by the operation, or -1 if the number is not known.

This number will always evaluate to true in a boolean context, even though
its arithmentic value may be equivalent to 0 (i.e. 0E0).

Because get* and set* use XML::Object's C<key_demand()> to locate their
'set' and 'get' sections, the @optional_path part of both these families of methods
can supply their own context. e.g. :

    sub example {
	my $self = shift;
	my $cfg = { set => { path => 'wherever.sql' } };
	my $rows_affected = $self->key_set($cfg, [ 'foo', 'bar' ]);
    }

C<key_set()> has the same relationship to C<set()> that C<key_get()> has 
to C<get()> i.e. it allows one to supply an explicit lookup path rather than
one automatically derived from the name of the current method.

=head2 setIter

=head2 key_setIter

=head3 usage

    sub example {
	my $accessor = $self->get(...);
	my $mutator = $self->setIter(...);
	while ($row = $get->hashref) {
	    $mutator->({ alpha => $row->{alpha}, beta => $row->{beta} }); 
	}
    }

=head3 description

Returns a closure that can be used to perform multiple mutations of a data source.
Each invocation of the closure performs the operation specified in the inline or
external SQL; any arguments passed to the closure are interpolated into the SQL in
accordance with the ARRAY ref and HASH ref conventions outlined in the C<set()>
section above.

Note that: arguments passed to C<setIter()> are treated as default bindings that can optionally
be overridden by arguments passed to the iterator itself. e.g:

    my $default = $self->setIter([ 'foo' , 'bar' ]);
    # foo and bar bind into the SQL by default 
    
    &$default;
    # use the default bindings 

    $default->([ 'alpha', 'beta' ]);
    # override the bindings for this call only

C<key_set()> has the same relationship to C<set()> that C<key_get()> has 
to C<get()> i.e. it allows one to supply an explicit lookup path rather than
one automatically derived from the name of the current method.

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

    my $array = $self->array2hash($fields, $hash);

=head3 description

Converts an ARRAY ref into an a HASH ref using the key provided by the $fields
ARRAY ref to attach keys to the supplied values.

This, in conjunction with C<hash2array()>, facilitates interchange between the HASH
and ARRAY ref types returned by the various accessors.

=head2 hash2array

=head3 usage

    my $array = $self->hash2array($fields, $hash);

=head3 description

Converts a HASH ref into an ARRAY ref using the key provided by the $fields
ARRAY ref to order the fields.

This, in conjunction with C<array2hash()>, facilitates interchange between the HASH
and ARRAY ref types returned by the various accessors.

=head1 EXCEPTIONS

=head2 XOE::BadArrayRef

Thrown if an ARRAY ref argument is expected but not supplied.

=head2 XOE::BadConnect

Thrown if the initial DBI connection fails.

=head2 XOE::BadExecute

Thrown if the DBI $sth->execute method fails.

=head2 XOE::BadFetch

Thrown if a retrieve operation on a DBI statement handle fails.

=head2 XOE::BadHashRef

Thrown if a HASH ref argument is expected but not supplied.

=head2 XOE::BadPrepare

Thrown if the DBI $sth->prepare method fails.

=head2 XOE::BadScalarFields

Thrown if the C<scalar()> or C<scalars()> is invoked on an accessor whose
n=head2 XOE::BadScalar

=head2 XOE::BadScalarRows

Thrown if the C<scalar()> is invoked on an accessor whose
number of rows is not equal to one

=head2 XOE::BadSet

Thrown if an error occurs while DBI->do() is performed on the SQL supplied to the
C<set()> mutator.

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
