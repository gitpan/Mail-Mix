use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	       'NAME'	      =>  'Mail::Mix',
	       'VERSION_FROM'  =>  'Mix.pm',
	       'PREREQ_PM'     =>  {
				    'Fcntl'           =>  0,
				    'Expect'          =>  0,
				    'POSIX'           =>  0,
				    'Mail::Internet'  =>  0,
				   },
	      );

