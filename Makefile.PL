use ExtUtils::MakeMaker;
use Config;

$Verbose=1 if $ENV{USER} eq "jvajda";

$| =1;
Init();

WriteMakefile(
    NAME	 => 'Finance::Bank::TB',
    DISTNAME	 => 'Finance-Bank-TB',
    VERSION_FROM => 'TB.pm',
    'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz' },
);

sub Init () {

print "Checking for Digest::SHA1, 1.02 or later         ... ";
	$@ = '';
	eval "use Digest::SHA1 1.02 ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Digest::SHA1 module, version 1.2 or later. I cannot
continue installing the Finance::Bank::TB module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

print "Checking for Crypt::DES, 2.03 or later ... ";
	$@ = '';
	eval "use Crypt::DES 2.03 ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Crypt::DES module, version 2.03 or later. I
cannot continue installing the Finance::Bank::TB module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

}
