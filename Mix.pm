# -*-cperl-*-
#
# Mail::Mix - An interface to mixmaster remailers.
# Copyright (c) 2000 Ashish Gulhati <hash@netropolis.org>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Mix.pm,v 1.7 2000/10/09 13:19:05 cvs Exp $

package Mail::Mix;

use 5.005;
use Fcntl;
use strict;
use Expect;
use Mail::Internet;
use POSIX qw (tmpnam);
use vars qw( $AUTOLOAD $VERSION );

( $VERSION ) = '$Revision: 1.7 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %args) = @_;
  bless {
	 'MIXDIR' => $args {MIXDIR},
	 'MIXCMD' => ($args {MIXDIR}) 
	              || (`which mixmaster` =~ /^(.*)\n$/ && $1)
	              || '/usr/bin/mixmaster',
	 'DEBUG'  => 0,
	}, $class;
}

sub AUTOLOAD {
  my ($self, $val) = @_; (my $auto = $AUTOLOAD) =~ s/.*:://;
  if ($auto =~ /^(mixdir|mixcmd|debug)$/) {
    $self->{"\U$auto"} = $val if defined $val;
    return $self->{"\U$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

sub chain {
  my $self = shift; my $mail = shift; my $path; my $x; my $tmpnam; my $tmpnam2;
  my @r = $self->remailers(); my @ret; my $i;
  my $chain = join ' ', map { if ($_) { $x = $_; ($x) = grep { $_->{Name} eq $x } @r; }
			      $_?$x->{Index}:0 } @_;
  do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  do { $tmpnam2 = tmpnam() } until sysopen(FH2, $tmpnam2, O_RDWR|O_CREAT|O_EXCL); 
  my $head = $mail->head(); my $headers = $head->as_string();
  my $recipients = join ('', ($head->get('To'), $head->get('Cc'), $head->get('Bcc')));
  my $body = join '', $mail->body(); $body .= "\n" unless $body =~ /\n/s;
  my $expect = Expect->spawn ("$self->{MIXCMD} -O $tmpnam2 -l $chain > $tmpnam2");
  $expect->log_stdout($self->{DEBUG}); 
  $expect->expect (undef, 'destinations'); print $expect "$recipients\n"; 
  $expect->expect (undef, 'headers'); print $expect "$headers\n";
  $expect->expect (undef, 'file to chain'); print $expect "$tmpnam\n"; 
  $expect->expect (undef); 
  foreach (<$tmpnam2*>) { 
    open (FH, $_); 
    $ret[$i++] = new Mail::Internet (<FH>); 
    close FH; unlink $_; 
  }
  unlink $tmpnam;
  return @ret;
}

sub remailers {
  my $self = shift; my $path; my $i = 0;
  $path = $ENV{MIXPATH}, $ENV{MIXPATH} = $self->{MIXDIR} if $self->{MIXDIR};
  my @mixlist = `$self->{MIXCMD} -T`;
  $ENV{MIXPATH} = $path if $self->{MIXDIR};
  return map { my @x = split (/\s+/);
               bless { Index => ++$i, Name => $x[0], Address => $x[1], Fingerprint => $x[2], 
                       Version => $x[3], Flags => $x[4] }, 'Mail::Mix::Remailer' } @mixlist;
}

=pod

=head1 NAME 

Mail::Mix - An interface to mixmaster remailers.

=head1 SYNOPSIS

  use Mail::Mix;
  my $mixmaster = new Mail::Mix;
  my @remailers = $mixmaster->remailers();
  my $message = new Mail::Internet( ['To: hash@netropolis.org', 
                                     '', 'This is a test'] );
  my @packets = $mixmaster->chain($message, $remailers->[0]->{Name}, 0);
  for (@packets) { $_->send (sendmail) }

=head1 DESCRIPTION

This module is a wrapper around Lance Cottrell's Mixmaster program,
and facilitates sending mail through mixmaster style remailers from
Perl.

=head1 CONSTRUCTOR

=over 2

=item B<new ()>

Creates a new Mail::Mix object.

=back

=head1 DATA METHODS

=over 2

=item B<mixbin ()>

Sets or reports the B<MIXBIN> instance variable, which should contain
the name of the Mixmaster executable.

=item B<mixdir ()>

Sets or reports the B<MIXDIR> instance variable, which should contain
the name of the Mixmaster data directory.

=item B<debug ()>

Sets or reports the B<DEBUG> instance variable. If this is set true,
the module will produce debugging output on its interaction with the
mixmaster program.

=back

=head1 OBJECT METHODS

=over 2

=item B<remailers()>

Returns a list of Mail::Mix::Remailer objects, which are hash
containers with the following attributes:

  Index        => The position of the remailer in the list
  Name         => The remailer's name
  Address      => The remailer's email address
  Fingerprint  => The remailer's key fingerprint
  Version      => Version of Mixmaster on the remailer
  Flags        => Flags 

=item B<chain($message, @remailerlist)>

Takes a Mail::Internet object and a list of remailer names, passes the
message through the mixmaster binary, and returns an array of
Mail::Internet objects containing the remailer packets. 

Each of the remailer names provided must correspond to the Name
attribute of one of the remailer objects returned by the
remailers() method. 

The special remailer name '0' may be used to specify a random
remailer.

=head1 BUGS

=over 2

=item * There is no error checking.

=head1 AUTHOR

Mail::Mix is Copyright (c) 2000 Ashish Gulhati <hash@netropolis.org>.
All Rights Reserved.

=head1 ACKNOWLEDGEMENTS

Thanks to Barkha for inspiration, laughs and all 'round good times;
and to Lance Cottrell, Larry Wall, Richard Stallman and Linus Torvalds
for all the great software.

=head1 LICENSE

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This is free software. If it breaks, you own both parts.

=cut

'True Value';
