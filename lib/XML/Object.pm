package XOE; # XML::Object::Exception

use strict;
use warnings;
use Error;
use base qw(Error::Simple);
use overload ('""' => \&Error::Simple::stringify);

$Error::Debug = 1;

sub new {
    my $self = shift;
    my $text = "" . (shift || '');

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;  # Enables storing of stacktrace

    $self->SUPER::new($text, @_);
}

1;

package XOE::BadConfig;
use base qw(XOE);

sub new {
    my ($class, $config_file) = @_;
    my $text = "configure: invalid path for configuration file: $config_file";
    my $self = $class->SUPER::new($text);
}
	
1;

package XOE::BadGrandparent;
use base qw(XOE);
1;

package XOE::BadLookup;
use base qw(XOE);

sub new {
    my ($class, $path) = @_;
    my $text = "_lookup: value not found: $path";
    my $self = $class->SUPER::new($text);
}

1;

package XOE::BadParent;
use base qw(XOE);

sub new {
    my $class = shift;
    my $text = "parent: caller not defined";
    my $self = $class->SUPER::new($text);
}

1;

package XOE::BadXML;
use base qw(XOE);
1;

package XML::Object;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use XML::Simple; # For slurping the configuration file
use Error qw(:try);
use Carp qw(confess); # report errors with stacktrace

sub new {
    my ($class, $config_file, %xmlopts) = @_;
    my $self = { _XML_OBJECT_ => { } };
    bless $self, $class;
    $self->configure($config_file, %xmlopts);
    return $self;
}

######################### Public Methods ################################

sub configure { # accessor/mutator for configuration file
    my ($self, $config_file, %xmlopts) = @_;
    my $obj = $self->{_XML_OBJECT_};

    if (defined $config_file) {
	throw XOE::BadConfig ($config_file) unless (-s $config_file);
	$self->{CONFIG_FILE} = $config_file; 
	$self->{XML_OPTS} = { %xmlopts }; 

	# SuppressEmpty to turn <foo></foo> into
	#   foo => ''
	# rather than
	#   foo => {}

	my $config;

	eval { $config = XMLin($config_file, SuppressEmpty => '', %xmlopts) };

	if ($@) {
	    throw XOE::BadXML ($@);
	} else {
	    $self->config($config);
	}
    } else {
	return wantarray ? ($self->{CONFIG_FILE}, $self->{XML_OPTS}) : $self->{CONFIG_FILE};
    }
}

sub config {
    my $self = shift()->{_XML_OBJECT_};
    my $config = shift;
    return $self->{CONFIG} unless ($config);
    $self->{CONFIG} = $config;
}

sub parent {
    my $self = shift()->{_XML_OBJECT_};
    my $caller = (caller(2))[3];
    throw XOE::BadParent() unless (defined $caller);
    $caller =~ s/^.+::(\w+)$/$1/;
    return $caller;
}

sub grandparent {
    my $self = shift()->{_XML_OBJECT_};
    my $caller = (caller(3))[3];
    throw XOE::BadGrandparent() unless (defined $caller);
    $caller =~ s/^.+::(\w+)$/$1/;
    return $caller;
}

# test to see whether specified configuration options are
# found in calling sub's namespace
sub test {
    my $self = shift;
    my $key = $self->parent();
    my @caller = ref $_[0] ? (shift, $key) : ($key); # keep the context (if supplied) at the start
    return $self->key_test(@caller, @_);
}

# require specified configuration options to be found in
# calling sub's namespace
sub demand {
    my $self = shift;
    my $key = $self->parent();
    my @caller = ref $_[0] ? (shift, $key) : ($key); # keep the context (if supplied) at the start
    return $self->key_demand(@caller, @_);
}

# test to see whether specified configuration options are found
# in grandparent sub's namespace
sub caller_test {
    my $self = shift;
    my $key = $self->grandparent();
    my @caller = ref $_[0] ? (shift, $key) : ($key); # keep the context (if supplied) at the start
    return $self->key_test(@caller, @_);
}

# require specified configuration options to be found
# in grandparent sub's namespace
sub caller_demand {
    my $self = shift;
    my $key = $self->grandparent();
    my @caller = ref $_[0] ? (shift, $key) : ($key); # keep the context (if supplied) at the start
    return $self->key_demand(@caller, @_);
}

# test to see whether specified configuration options
# are found in key's namespace
sub key_test {
    my $self = shift;
    return $self->_lookup(0, @_);
}

# require specified configuration options to be found
# in key's namespace
sub key_demand { 
    my $self = shift;
    return $self->_lookup(1, @_);
}

######################### Private Methods ################################

sub _lookup {
    my $self = shift;
    my $demand = shift;
    my $result = (ref $_[0]) ? shift : $self->config();
    my @args = @_; # copy the path so we can use it in the diagnosis

    while ((defined $result)  && (ref ($result) =~ '^(?:ARRAY|HASH)$') && (scalar @_)) {
	$result = (ref $result eq 'ARRAY') ? $result->[shift()] : $result->{shift()};
    }

    if ($demand) {
	return $result if (defined $result);
	throw XOE::BadLookup (join ' / ', @args);
    } else {
	return $result;
    }
}

1;

__END__

=head1 NAME

    XML::Object - Methodical XML Configuration

=head1 SYNOPSIS

=head2 XML

    <config>
	<run name="John Doe">
	    <port>4321</port>
	    <user>bar</user>
	</run>
	<foo>
	    <port>1234</port>
	    <bar>
		<baz>Luhrmann</baz>
	    </bar>
	    <list>alpha</list>
	    <list>
		<beta>gamma</beta>
	    </list>
	    <list>vlissides</list>
	    <email>foo@bar.com</email>
	    <address>1 Foo Street, Bar FB1 1FB</address>
	</foo>
	<user>foo</user>
    </config>

=head2 XML::Simple

    {
	run => {
	    name    => 'John Doe',
	    port    => '4321',
	    user    => 'bar'
	},
	foo => {
	    port    => '1234',
	    bar	    => {
		baz => 'Luhrmann'
	    },
	    list => [
		'alpha',
		{
		    'beta' => 'gamma'
		},
		'vlissides'
	    ],
	    email   => 'foo@bar.com',
	    address => '1 Foo Street, Bar FB1 1FB'
	},
	user => 'foo'
    }

=head2 main.pl

    use Foo;

    # call from a subroutine to demonstrate caller_test() / caller_demand()
    sub run { 
	my $foo = Foo->new($config_file, %optional_xml_simple_options);
	$foo->foo();
    }

    run();

=head2 Foo.pm

    package Foo;

    use base qw(XML::Object);
    # package can now configure itself via XML

    # optional constructor
    sub new {
	my $class = shift;
	my $self = $class->SUPER(@_);

	# ...
    }

    sub foo {
	my $self = shift;

	# optional: test() returns undef if the value isn't found
	# equivalent to $self->config()->{foo}->{port} 
	my $port = $self->test('port') || 8080;

	# compulsory: demand() throws an exception if the value isn't found
	# equivalent to $self->config()->{foo}->{email} 
	my $email = $self->demand('email');

	# arbitrarily deep path expressions
	# equivalent to $self->config()->{foo}->{list}->[1]->{beta} 
	my $leaf = $self->demand('list', 1, 'beta');

	# provide an explicit key: $self->config()->{user} 
	my $user = $self->key_test('user');

	# use the name of the function that called this function as the root
	# equivalent to $self->config()->{run}->{name}
	my $name = $self->caller_demand('name');

	# equivalent to $self->key_demand('foo')  i.e. $self->config()->{foo}
	my $foo = $self->demand();

	# supply your own configuration HASH or ARRAY ref
	my $alpha = $self->key_test($array_or_hash_ref, 'alpha');
	my $beta = $self->key_demand($array_or_hash_ref, 'beta');
    }

=head1 DESCRIPTION

XML::Object allows easy (XML) configuration of a Perl script/module
by associating methods with elements. Because each method has its
own configuration 'namespace', the structure of the XML reflects
that of the object and vice-versa. This partitioning leads to a
simple and intuitive organisation of the configuration space.

XML::Object::DBI adds a database accessor (get) and mutator (set) to
the mix. These shield the user from DBI housekeeping while freeing them
to manage the SQL in an intuitive and flexible way.

=head1 METHODS

=head2 test

=head3 usage

    sub example {
	my $self = shift;

	# i.e. $self->key_test('example', 'port');
	my $optional1 = $self->test('port') || 8080;

	    # or 

	# i.e. $self->key_test($hash_or_array_ref, 'example', 'port');
	my $optional2 = $self->test($hash_or_array_ref, 'port');
    }

=head3 summary

C<test()> looks up a scalar, ARRAY ref or HASH ref using the name
of the current subroutine and any supplied arguments as the root
(i.e. first HASH key or ARRAY index) of the path into the configuration
HASH or ARRAY ref.

Numbers and strings in the path are interpreted according
to the context discovered during the course of the lookup.
Thus in the following example:

    sub foo {
	my $self = shift;
	my $test = $self->test('list', 1, 'beta');
    }

That path is first translated into the equivalent of:

    $self->key_test('foo', 'list', 1, 'beta');

Which in turn becomes:

    $self->config()->{foo}->{list}->[1]->{beta} 

C<test()>, C<demand()>, C<caller_test()>, C<caller_demand()>, C<key_test()> and
C<key_demand()> can be passed a HASH or ARRAY ref as the first
argument. The lookup is then performed against this structure
rather than the object's configuration HASH/ARRAY ref.

e.g.

    my $login = $self->demand('login'); # grab the login HASH
    my $user = $self->key_demand($login, 'username'); # compulsory username
    my $password = $self->key_test($login, 'password'); # optional password

=head2 demand

=head3 usage

    sub example {
	my $self = shift;

	# i.e. $self->key_demand('example', 'user');
	my $compulsory1 = $self->demand('user');

	    # or

	# i.e. $self->key_demand($array_or_hash_ref, 'example', 'user');
	my $compulsory2 = $self->demand($array_or_hash_ref, 'user');
    }

=head3 summary

C<demand()> works the same as C<test()>, but raises an exception
if the specified value is not defined or the path is invalid.

=head2 caller_test

=head3 usage

    sub run {
	my $self = shift;
	$self->example();
    }

    sub example {
	my $self = shift;

	# i.e. $self->key_test('run', 'port');
	my $optional1 = $self->caller_test('port') || 8080;

	    # or 

	# i.e. $self->key_test($array_or_hash_ref, 'run', 'port');
	my $optional2 = $self->caller_test($array_or_hash_ref, 'port') || 8080;
    }

=head3 summary

C<caller_test()> uses the name of the subroutine that called the
current subroutine as the root of the path. Otherwise its use
is the same as C<test()>.

=head2 caller_demand

=head3 usage

    sub run {
	my $self = shift;
	$self->example();
    }

    sub example {
	my $self = shift;

	# i.e. $self->key_demand('run', 'user');
	my $compulsory1 = $self->caller_demand('user');

	    # or

	# i.e. $self->key_demand($array_or_hash_ref, 'run', 'user');
	my $compulsory2 = $self->caller_demand($array_or_hash_ref, 'user');
    }

=head3 summary

C<caller_demand()> uses the name of the subroutine that called the
current subroutine as the root of the path. Otherwise its use
is the same as C<demand()>.

=head2 key_test

=head3 usage

    sub example {
	my $self = shift;

	my $optional = $self->key_test('port') || 8080;
	    # or
	my $optional = $self->key_test($array_or_hash_ref, 'port') || 8080;
    }

=head3 summary

C<key_test()> uses only the explicitly specified key(s)
to index into the default or supplied configuration ARRAY
or HASH ref. The other flavours of C<test()> are implemented
as wrappers of C<key_test()>.

=head2 key_demand

=head3 usage

    sub example {
	my $self = shift;
	my $compulsory1 = $self->key_demand('user');
	    # or
	my $compulsory2 = $self->key_demand($array_or_hash_ref, 'user');
    }

=head3 summary

C<key_demand()> uses only the explicitly specified key(s)
to index into the default or supplied configuration ARRAY
or HASH ref. The other flavours of C<demand()> are implemented
as wrappers of C<key_demand()>.

=head2 configure

=head3 usage

    my $path = $self->configure();

	# or 

    my ($path, $xml_simple_options) = $self->configure();

	# or 

    $self->configure($path, %optional_xml_simple_args);

=head3 summary

When called with no arguments C<configure()> returns a) the path to the 
configuration file in scalar context, or b) the path and a reference to
the (possibly empty) HASH of C<XML::Simple::XMLin()> options in list context.

When called with a path argument and an optional HASH of arguments to be
supplied to XML::Simple's C<XMLin()>, a new configuration HASH or ARRAY
ref is initialized in the object and returned.

=head2 config

=head3 usage

    my $config = $self->config();

	# or 

    $self->config($array_or_hash_ref);

=head3 summary

When called with no arguments C<config()> returns the configuration HASH
ref or ARRAY ref associated with the object.

When called with an argument that value is assigned as the object's new
configuration.

=head2 parent

=head3 usage

    my $caller = $self->parent();

=head3 summary

Returns the name (minus namespace) of the subroutine that
called the current subroutine. Throws an exception unless that
value is defined.

=head2 grandparent

=head3 usage

    my $caller_caller = $self->grandparent();

=head3 summary

Returns the name (minus namespace) of the subroutine that
called the subroutine that called the current subroutine. Throws
an exception unless that value is defined.

=head1 EXCEPTIONS

=head2 XOE

Superclass for all XML::Object Exceptions.

=head2 XOE::BadConfig

Thrown if an attempt is made to assign an invalid (i.e. nonexistent or zero-length) configuration file.

=head2 XOE::BadGrandparent

Thrown if a caller_get* or caller_set* method is invoked in a context in which
the call stack isn't deep enough for the grandparent of the caller_* method
to be identified.

=head2 XOE::BadLookup

Thrown if a C<demand()> fails either a) by being resolved to a value that is undefined
or b) if the path is not valid within the configuration ARRAY or HASH ref.

=head2 XOE::BadParent

Thrown if a get* or set* method is invoked in a context in which
the call stack isn't deep enough for the parent of the get* or set* method
to be identified.

=head2 XOE::BadXML

Thrown if an error occurs during XML::Simple's C<XMLin()> routine, which turns the specified
XML into a Perl data structure.

=head1 EXPORT

    None by default.

=head1 SEE ALSO

    XML::Object::DBI, XML::Simple

=head1 AUTHOR

    chocolateboy <chocolate.boy@email.com>

=head1 COPYRIGHT AND LICENSE

    Copyright 2003 by chocolateboy

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself. 

=cut
