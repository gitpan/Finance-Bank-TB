#!/usr/bin/perl -w

use lib qw(./blib/lib);

use Bank::TB;

$mid = '007';
$key = 'JimiBond';

my $tb_obj = Bank::TB->new($mid,$key);

$vs = '3350078';
$amt = '516';
$rurl = 'http://www.server.sk/Your/Reply/Page';

$tb_obj->configure(
                cs => '558',
                vs => $vs,
                amt => $amt,
                rurl => $rurl,
                rsms => '903666666',
                desc => 'Example_Description',
                name => 'Kozo',
                ipc => '194.154.247.14',
                rem => 'kozo@pobox.sk',
        );

print $tb_obj->card_link();
