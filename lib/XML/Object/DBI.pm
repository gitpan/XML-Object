package XML::Object::DBI;

use strict;
use warnings;
use base qw(XML::Object);
use Carp qw(confess);
use DBI;

our $VERSION = '0.01';

# use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Terse = 1;

sub new {
    my ($class, $config_file) = @_;
    my $self = $class->SUPER::new($config_file);
    bless $self, $class;

    my $dbi = $self->key_demand('dbi');
    my $dsn = $self->demand($dbi, 'dsn');
    my $username = $self->demand($dbi, 'username');
    my $password = $self->demand($dbi, 'password');
    $self->dbh( [ $dsn, $username, $password ] );

    return $self;
}

# tidy up database handle when this object is destroyed
sub DESTROY {
    my $self = shift;
    my $dbh = $self->dbh();
    $dbh->disconnect();
    $self = undef;
}

# accessor/mutator for database handle
sub dbh {
    my ($self, $db) = @_;
    if (defined $db) {
        confess ("dbh: db args not an array ref") unless ($db && (ref $db) && (ref $db eq 'ARRAY'));
        my (@missing, $index) = qw(dsn username password 0);
        confess ("dbh: $missing[$index] not defined") unless (grep({ defined $_ and ++$index } @$db) == 3);
        my ($dsn, $user, $password) = @$db;
        $self->{_XML_OBJECT_}->{DBH} = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 0 });
    } else {
        confess ("dbh: database handle not defined") unless (exists $self->{_XML_OBJECT_}->{DBH});
        return $self->{_XML_OBJECT_}->{DBH};
    }
}

# model() throws an error if returning more than 1 row in scalar context
# in array context it is legal for it to return 1 or more rows

sub key_model {
    my ($self, $key, @args) = @_;
    my ($template, $columns, $array);
    # my $model = $self->caller_demand('model');
    my $model = $self->key_demand($key, 'model');

    if (ref $model) {
        ($template, $columns, $array) = @{$model}{qw(content columns array)};
    } else {
        $template = $model
    }

    $template .= ';' unless ($template =~ /;$/);
    my $sql = sprintf $template, @args;
    # print "SQL: $sql", $/;
    my $dbh = $self->dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my $array_ref = $array ? $sth->fetchall_arrayref() : $sth->fetchall_arrayref({});
    my $rows = $#$array_ref + 1;
    my $context = wantarray;

    if ($context && $rows) { # list context, one or more rows
        return $columns ? ($sth->{NAME}, @$array_ref) : @$array_ref; # prepend column names if called in list context
    } elsif (defined $context) { # scalar context
        confess ("model: invalid number of rows: expected 1 got $rows") unless ($rows == 1);
        confess ("model: can't return column names when called in scalar context") if ($columns);
        return $array_ref->[0];
    } else {
        confess ("model: not implemented: calling model() in a void context");
    }
}

sub model {
    my $self = shift;
    my $key = $self->parent();
    unshift @_, $self, $key;
    goto &key_model;
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
