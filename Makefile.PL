use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Object',
    'VERSION_FROM'	=> 'lib/XML/Object.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
	'Error'		=> 0.15,
	'XML::Simple'	=> 0,
	'Test::More'	=> 0,
	'Util'		=> 0.02
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
      # ABSTRACT_FROM => 'Object.pm', # retrieve abstract from module
       AUTHOR     => 'chocolateboy: <chocolate.boy@email.com>') : ()),
);
