##############################################################################
#
#  Copyright (c) 2000 Jan 'Kozo' Vajda <Jan.Vajda@pobox.sk>
#  All rights reserved.
#
##############################################################################

package Finance::Bank::TB;
require Exporter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Digest::SHA1;
use Crypt::DES 2.01;

### my initial version was 0.11
$VERSION = '0.22';

@ISA = qw(Exporter);

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();


=head1 NAME

  Finance::Bank::TB - Perl extension for B<TatraPay> of Tatra Banka and B<EliotPay> of .eliot.

=head1 VERSION

  0.22

=head1 SYNOPSIS

  use Finance::Bank::TB;

  $tb_obj = Finance::Bank::TB->new($mid,$key);

  $tb_obj->configure(
	      cs	=> $cs,
	      vs	=> $vs,
	      amt	=> $amt,
	      rurl	=> $rurl,
	      image_src => '/PICS/tatrapay_logo.gif',
	);

  my $send_sign = $tb_obj->get_send_sign();
  my $recv_sign = $tb_obj->get_recv_sign();
  my $new_cs = $tb_obj->cs($cs);

  or

  use Finance::Bank::TB;

  $tb_obj = Finance::Bank::TB->new($mid,$key);

  $tb_obj->configure(
	      cs	=> $cs,
	      vs	=> $vs,
	      amt	=> $amt,
	      rurl	=> $rurl,
	      desc	=> $description,
	      rsms	=> $mobilephonenumber,
	      rem	=> $remote_mail,
	      image_src => '/PICS/tatrapay_logo.gif',
	);

  print $tb_obj->pay_form();

=head1 DESCRIPTION

  Module for generating signatures and pay forms for B<TatraPay> of Tatra
  Banka (http://www.tatrabanka.sk/) and for B<EliotPay> of .eliot.
  (http://www.eliot.sk/)

=head1 USE

=head2 Functions ( or Methods ? )

=item new

	$tb_obj  = Finance::Bank::TB->new($mid,$key);

This creates a new Finance::Bank::TB object using $mid as a MID ( MerchantID ) and
$key as a DES PassPhrase.

=cut


sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	croak "Usage $class->new (MID, KEY)" if ( @_ != 2 ) ;
	my $self = {};
	bless $self, $class;

	$self->{'mid'} = shift;
	$self->{'tbkey'} = shift;

	croak "KEY must be 8 chars" if ( length($self->{'tbkey'}) != 8 );
	
	$self->_init;

	return($self);
}

sub _init {
  my $self = shift;

  ### default values
  $self->{'action_url'} = "https://moja.tatrabanka.sk/cgi-bin/ibanking/start/e-commerce.jsp";
  $self->{'tatra_action_url'} = "https://moja.tatrabanka.sk/cgi-bin/ibanking/start/tatrapay.jsp";
  $self->{'eliot_action_url'} = "https://moja.tatrabanka.sk/cgi-bin/ibanking/start/eliotpay.jsp";
  $self->{'image_src'} = '/PICS/tatrapay_logo.gif';

  return($self);
}


=item configure

	$tb_obj->configure(
		cs        => $cs,
		vs        => $vs,
		amt       => $amt,
		rurl      => $rurl,
		image_src => '/PICS/tatrapay_logo.gif',
	);

 
Set correct values to object.
Possible parameters is:
        cs => Constant Symbol
       vs  => Variable Symbol
       amt => Amount
      rurl => Redirect URL
 image_src => Path to image ( relative to DocumentRoot )
      desc => Description
      rsms => Mobile Number for SMS notification
       rem => E-mail address for email notification
           
Possible but default correct parameters is:
 
  tatra_action_url => TatraPay action URL
  default:
    https://moja.tatrabanka.sk/cgi-bin/ibanking/start/e-commerce.jsp

  eliot_action_url => EliotPay action URL
  default:
    https://moja.tatrabanka.sk/cgi-bin/ibanking/start/eliotpay.jsp

  action_url => default action URL
  default:
    https://moja.tatrabanka.sk/cgi-bin/ibanking/start/e-commerce.jsp

  image_src => Path to image ( relative to DocumentRoot )
  default:
    /PICS/tatrapay_logo.gif

    

=cut

sub configure {
	my $self = shift;
	my (%arg) = @_;

	### normalization
	foreach (keys %arg) {
		### konvert name to lowercase
		$self->{"\L$_"} = $arg{$_};
	}
	return($self);
}

=item calculate_signatures

  $tb_obj->calculate_signatures();
  print $tb_obj->send_sign;
  print $tb_obj->recv_sign;

  Calculate Send and Receive Signature from parameters of  object and set
  send_sign and recv_sign.

=cut

sub calculate_signatures {
  my $self =shift;
  
  $self->get_send_sign();
  $self->get_recv_sign();
  
}

=item get_send_sign

  print $tb_obj->get_send_sign();
  
  Calculate and return send signature.
  Set $tb_obj->send_sign.

=cut


sub get_send_sign {

  my $self =shift;

  my $key = $self->{'tbkey'};

  # make string from incoming values
  my $initstr = join('',$self->{mid},
			$self->{amt},
			$self->{vs},
			$self->{cs},
			$self->{rurl}
		);

  return($self->{send_sign} = _make_sign($key,$initstr));
}

=item get_recv_sign

  print $tb_obj->get_send_sign();
  
  Calculate and return receive signature.
  Set $tb_obj->recv_sign.

=cut

sub get_recv_sign {

  my $self =shift;

  my $key = $self->{'tbkey'};

  # make string from incoming values
  my $initstr = join('',$self->{vs},
			$self->{res}
		);

  return($self->{recv_sign} = _make_sign($key,$initstr));
}

=item pay_form

  print $tb_obj->pay_form($type);

  Type is "tatrapay" or "eliot" or null. Default is null (action_url).
  Recomended is null.
  
  Return HTML FORM.

=cut

sub pay_form {
  my $self =shift;
  my $type = shift || 'tatrapay';
  my $action;

  if ( $type eq 'eliot' ) {
    $action = $self->{eliot_action_url};
  } elsif ( $type eq 'tatra' ){
    $action = $self->{tatra_action_url};
  } else {
    $action = $self->{action_url};
  }

  my $sign = $self->get_send_sign();

my $tb_form = <<EOM;
<!-- tatra banka & eliot ePay form start -->
<form action="$action" method=POST>
<input type=hidden name=MID value="$self->{mid}">
<input type=hidden name=AMT value="$self->{amt}">
<input type=hidden name=VS value="$self->{vs}">
<input type=hidden name=CS value="$self->{cs}">
<input type=hidden name=RURL value="$self->{rurl}">
<input type=hidden name=DESC value="$self->{desc}">
<input type=hidden name=RSMS value="$self->{rsms}">
<input type=hidden name=REM value="$self->{rem}">
<input type=hidden name=SIGN value="$sign">
<input type=image src="$self->{image_src}" border=0>
</form>
<!-- tatra banka & eliot ePay form end -->
EOM

  return($tb_form);
}


=item pay_link

  print $tb_obj->pay_link($type);

  Type is "tatrapay" or "eliot" or null. Default is null (action_url).
  Recomended is null.

  Return URL for payment.

=cut

sub pay_link {
  my $self =shift;
  my $type = shift || 'tatrapay';
  my $action;

  if ( $type eq 'eliot' ) {
    $action = $self->{eliot_action_url};
  } elsif ( $type eq 'tatra' ){
    $action = $self->{tatra_action_url};
  } else {
    $action = $self->{action_url};
  }

  my $sign = $self->get_send_sign();

my $tb_form = <<EOM;
$action ?
MID=$self->{mid} & 
AMT=$self->{amt} & 
VS=$self->{vs} & 
CS=$self->{cs} & 
RURL=$self->{rurl} & 
DESC=$self->{desc} & 
RSMS=$self->{rsms} & 
REM=$self->{rem} & 
SIGN=$sign 
EOM

$tb_form =~ s/\n//og;
$tb_form =~ s/\s+//og;

  return($tb_form);
}


=item generic_pay_form

  print $tb_obj->generic_pay_form($type);

  Type is "tatrapay" or "eliot" or null. Default is null (action_url).
  Recomended is null.

  Return HTML FORM for payment with submit button.

=cut

sub generic_pay_form {
  my $self =shift;
  my $type = shift || 'tatrapay';
  my $action;

  if ( $type eq 'eliot' ) {
    $action = $self->{eliot_action_url};
  } elsif ( $type eq 'tatra' ){
    $action = $self->{tatra_action_url};
  } else {
    $action = $self->{action_url};
  }

  my $sign = $self->get_send_sign();

my $tb_form = <<EOM;
<!-- tatra banka & eliot ePay form start -->
<form action="$action" method=POST>
<input type=hidden name=MID value="$self->{mid}">
<input type=hidden name=AMT value="$self->{amt}">
<input type=hidden name=VS value="$self->{vs}">
<input type=hidden name=CS value="$self->{cs}">
<input type=hidden name=RURL value="$self->{rurl}">
<input type=hidden name=DESC value="$self->{desc}">
<input type=hidden name=RSMS value="$self->{rsms}">
<input type=hidden name=REM value="$self->{rem}">
<input type=hidden name=SIGN value="$sign">
<input type=submit value="Suhlasim">
</form>
<!-- tatra banka & eliot ePay form end -->
EOM

  return($tb_form);
}

sub _make_sign {
  my $key = shift;
  my $initstr = shift;

  ### make SHA hash
  my $context = new Digest::SHA1;
  $context->add($initstr);
  my $tb_hash = $context->digest;

  ### first 8 chars
  my $tb_hash_part = substr($tb_hash,0,8);

  ### crypting by DES
  my $cipher = Crypt::DES->new($key);
  my $tb_des = $cipher->encrypt($tb_hash_part);

  ### to hex
  my $tb_hash_hex = unpack("H16", $tb_des);

  ### convert to upper case and return
  return("\U$tb_hash_hex");
}

sub AUTOLOAD {
  my $self = shift;
  my $value = shift;
  my ($name) = $AUTOLOAD;

  ($name) = ( $name =~ /^.*::(.*)/);

  $self->{$name} = $value if ( defined $value );

  return($self->{$name});
 
}

sub DESTROY {
  ### bye bye 
}

1;

__END__

=head1 EXAMPLES

  Look at B<SYNOPSIS>, t/*, examples/* and use the source.
  ( lookin for a volunteer for writing documentation and man pages)

=head1 AUTHOR INFORMATION

  Copyright 2000 Jan ' Kozo ' Vajda, Jan.Vajda@somi.sk. All rights
reserved.  It may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module as
you wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
Jan.Vajda@somi.sk

=head1 CREDITS

Thanks very much to:

=over 4

=item my wife Erika

for patience

=item Gildir ( gildir@alert.sk ) 

for debugging

=item M. Sulik from TatraBanka

for documentation, C examples and mail helpdesk.

=back

=head1 SEE ALSO

  perl(1),Digest::SHA1(1),Crypt::DES(1).

=cut
