package XML::Object;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use XML::Simple; # For slurping the configuration file
use Carp qw(confess); # report errors with stack trace

sub new {
    my ($class, $config_file) = @_;
    my $self = { _XML_OBJECT_ => { } };
    bless $self, $class;
    $self->configure($config_file);
    return $self;
}

sub configure { # accessor/mutator for configuration file
    my ($self, $config_file) = @_;
    my $obj = $self->{_XML_OBJECT_};

    if (defined $config_file) {
	confess ("configure: invalid path for configuration file: $config_file") unless (-s $config_file);
	$self->{CONFIG_FILE} = $config_file; 
	$self->config(XMLin($config_file));
    } else {
	confess ("configure: no configuration file defined") unless (exists $self->{CONFIG_FILE});
	return $self->{CONFIG_FILE};
    }
}

sub config {
    my $self = shift()->{_XML_OBJECT_};
    my $config = shift;
    return $self->{CONFIG} unless ($config);
    $self->{CONFIG} = $config;
}

sub lookup { # read-only - config can only be set via configure
    my $self = shift;
    my $demand = shift;
    my $result = (ref $_[0]) ? shift : $self->config();
    my @args = @_; # copy the path so we can use it in the diagnosis

    while ((defined $result)  && (ref ($result) =~ '^(?:ARRAY|HASH)$') && (scalar @_)) {
	$result = (ref $result eq 'ARRAY') ? $result->[shift()] : $result->{shift()};
    }

    if ($demand) {
	return $result if (defined $result);
	confess ('lookup: value not found: ' . join (' / ', @args));
    } else {
	return $result;
    }
}

sub _demand { 
    my $self = shift;
    return $self->lookup(1, @_);
}

sub _test {
    my $self = shift;
    return $self->lookup(0, @_);
}

sub parent {
    my $self = shift()->{_XML_OBJECT_};
    my $caller = (caller(2))[3];
    confess ("parent: caller not defined") unless (defined $caller);
    $caller =~ s/^.+::(\w+)$/$1/;
    return $caller;
}

sub grandparent {
    my $self = shift()->{_XML_OBJECT_};
    my $caller = (caller(3))[3];
    confess ("grandparent: caller's caller not defined") unless (defined $caller);
    $caller =~ s/^.+::(\w+)$/$1/;
    return $caller;
}

sub test { # test to see whether specified configuration options are found in calling sub's namespace
    my $self = shift;
    my $caller = ref $_[0] ? shift : $self->parent();
    return $self->_test($caller, @_);
}

sub demand { # require specified configuration options to be found in calling sub's namespace
    my $self = shift;
    my $caller = ref $_[0] ? shift : $self->parent();
    return $self->_demand($caller, @_);
}

sub caller_test { # test to see whether specified configuration options are found in grandparent sub's namespace
    my $self = shift;
    my $caller = ref $_[0] ? shift : $self->grandparent();
    return $self->_test($caller, @_);
}

sub caller_demand { # require specified configuration options to be found in grandparent sub's namespace
    my $self = shift;
    my $caller = ref $_[0] ? shift : $self->grandparent();
    return $self->_demand($caller, @_);
}

sub key_test { # test to see whether specified configuration options are found in key's namespace
    my $self = shift;
    my $key = shift;
    return $self->_test($key, @_);
}

sub key_demand { # require specified configuration options to be found in key's namespace
    my $self = shift;
    my $key = shift;
    return $self->_demand($key, @_);
}

1;

# __END__

=head1 XML::Object

    XML::Object - Functionality encapsulated in methods - configuration encapsulated in elements

=head1 SYNOPSIS

    use XML::Object;

    use base qw(XML::Object);

    # current package can now configure itself via XML:

    <config>
	<foo>
	    <email>foo@bar.com</email>
	    <address>foo@bar.com</address>
	    <name>foo@bar.com</name>
	</foo>
	<bar>
	    <email>foo@bar.com</email>
	    <address>foo@bar.com</address>
	    <name>foo@bar.com</name>
	</bar>
	<baz>
	    <email>foo@bar.com</email>
	    <address>foo@bar.com</address>
	    <name>foo@bar.com</name>
	</baz>
    </config>

    sub new {
	my $class = shift;
	my $self = $class->SUPER(@_); # XML::Object data is kept under { _XML_OBJECT_ => ... }
	$self->{FOO} = 'bar';
	$self->{BAR} = 'baz';
	bless $self, ref $class || $class;
    }

    sub foo {
	my $email = $self->demand('email'); # demand() throws an error if the value isn't specified
	my $address = $self->test('address'); # test() returns undef if the value isn't found
	my $name = $self->caller_request('address'); # the value returned varies according to the name of the function that called foo
    }

=head1 ABSTRACT

    This module allows easy configuration of a perl script via XML. Functionality can
    be broken up into methods which receive a subclass of the XML::Object object as the first argument.
      
    Configuration is then typically made available on a per-method basis.
  
=head1 DESCRIPTION

=head2 EXPORT

    None by default.

=head1 SEE ALSO

    XML::Simple

=head1 AUTHOR

    chocolateboy <chocolateboy@chocolatey.com>

=head1 COPYRIGHT AND LICENSE

    Copyright 2003 by chocolateboy

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself. 

=cut
