#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..2\n"; }

use Finance::Bank::TB;

sub do_test
{
  my ($num, $key, $expect, $amt, $vs, $cs, $rurl ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('002',$key);

  $myob1->configure(
		cs => $cs,
		vs => $vs,
		amt => $amt,
		rurl => $rurl,
	);

  my $result = $myob1->get_send_sign();
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

sub do_test1
{
  my ($num, $key, $expect, $vs, $res ) = @_;

  print "EXPECT:   $expect\n";

  $myob1 = Finance::Bank::TB->new('002',$key);

  $myob1->configure(
		vs => $vs,
		res => $res,
	);

  my $result = $myob1->get_recv_sign();
  print "RESULT:   $result\n";
  print "not " unless ($result eq $expect);
  print "ok $num\n";
  return();
}

print "If the following results don't match, there's something wrong.\n\n";

do_test("1", "12345678" , "F20608EC16A90053",
	'105.30', '458299', '308', 'http://www.pobox.sk/tbib.html', 'OK'
);

do_test1("2", "87654321" , "0827FA8C0DBDB9B5",
	 '458299', 'OK'
);

