#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..2\n"; }

use Finance::Bank::TB;

sub do_test
{
  my ($num, $key, $expect, $amt, $vs, $cs, $rurl, $ipc, $name ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('007',$key);

  $myob1->configure(
		cs => $cs,
		vs => $vs,
		amt => $amt,
		rurl => $rurl,
		ipc => $ipc,
		name => $name,
	);

  my $result = $myob1->get_card_sign();
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

sub do_test1
{
  my ($num, $key, $expect, $vs, $res, $ac ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('002',$key);

  $myob1->configure(
		vs => $vs,
		res => $res,
		ac => $ac,
	);

  my $result = $myob1->get_recv_sign();
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

print "If the following results don't match, there's something wrong.\n\n";

do_test("1", "JimiBond" , "A704D40D61BBD84F",
	'516', '3350078', '558', 'http://www.server.sk/Your/Reply/Page',
	'194.154.247.14','Kozo',
);

do_test1("2", "87654321" , "8F7DAA136EA65F55",
	 '458299', 'OK',"huh ? any approval code"
);

