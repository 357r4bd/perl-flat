use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
                    NAME          => 'FLAT',
                    VERSION_FROM  => 'lib/FLAT.pm',
                    PREREQ_PM     => { Parse::RecDescent => 0,},
                    PL_FILES     => {'bin/util-put.pl', 'bin/util-put'},
    ($] >= 5.005 ? (ABSTRACT_FROM => 'lib/FLAT.pm',
                    AUTHOR        => 'perl-flat')
                 : ()),
);
