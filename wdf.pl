#!perl

# wdf.pl
# pod at tail

use warnings;            # avoid D'oh! bugs
use strict;              # avoid D'oh! bugs
use Win32::AdminMisc;    # host+drive stuff    (www.roth.net/perl/packages)
use Win32::EventLog;     # log program runs        (core ActivePerl module)
use POSIX;               # round decimal places    (core ActivePerl module)
use Net::SMTP;           # email notification      (core ActivePerl module)
use File::Spec;          # strip path from $0      (core ActivePerl module)
use Tie::IxHash;         # ordered hash            (core ActivePerl module)
use Getopt::Long;        # options & arguments     (core ActivePerl module)
use Pod::Usage;          # elim redundant Usage()  (core ActivePerl module)
$|++;                    # make STDOUT hot
my $VERSION = '0.09.07';


 ## PRELIMINARIES ##
my $host = Win32::AdminMisc::GetComputerName();
my ($notUsed,$not_used,$program) = File::Spec->splitpath( $0 );


 ## OPTIONS+ARGUMENTS ##
my ($arg_lowFree, @arg_recipients, $arg_smtp);
my ($opt_eventLog, $opt_versions, $opt_help, $opt_man);

GetOptions(
  'lowfree=i'   => \$arg_lowFree,
  'recipient=s' => \@arg_recipients,
  'smtp=s'      => \$arg_smtp,
  'eventlog!'   => \$opt_eventLog,
  'versions!'   => \$opt_versions,
  'help!'       => \$opt_help,
  'man!'        => \$opt_man,
) or pod2usage(-verbose => 1) && exit;

push my @eventLogStrings, "  = $program run started =" if($opt_eventLog);
pod2usage(-verbose => 1) && exit if $opt_help;
pod2usage(-verbose => 2) && exit if $opt_man;
pod2usage(-verbose => 1) && exit unless $arg_lowFree && $arg_lowFree > 0;
$arg_smtp = $host unless $arg_smtp;




 ## QUERY DRIVES, GEN INDIVIDUAL DRIVE REPORTS ##
my (@report, @lowDrives);
my @drives=Win32::AdminMisc::GetDrives(DRIVE_FIXED);
for my $drive(@drives){
  my ($total, $free) = Win32::AdminMisc::GetDriveSpace($drive);
  next unless $total;
  my $used           = $total-$free;
  my $percentUsed    = Round(($used/$total)*100);
  my $percentFree    = Round(($free/$total)*100);
  my($cTotal, $cUsed, $cFree) = Commify(Round($total, $used, $free));

  my $report = "
  $drive
  $percentUsed percent used
  $percentFree percent free

  $cTotal bytes total
  $cUsed bytes used
  $cFree bytes free";
  push @report, $report;
  push @lowDrives, $drive if($percentFree < $arg_lowFree);
}


 ## COMBINE INDIVIDUAL REPORTS INTO MESSAGE ##
my $low    = @lowDrives > 0 ? join(' and ', @lowDrives) : 'No';
my $plural = @lowDrives == 1 ? '' : 's';
my $alarum = "  $host $low drive$plural less than ${arg_lowFree}% free space";
unshift @report, $alarum;
my $message = join("\n", @report);
print "\n$message\n";
push @eventLogStrings, "  = $program report =\n$message" if($opt_eventLog);


 ## OPTIONAL EMAIL NOTIFICATION ##
if(@arg_recipients && @lowDrives > 0){
  my $autoMsg = 
    "Message automatically generated by $program program and sent to:";
  my $recipListMsg = join("\n  ", @arg_recipients);
  for my $recipient(@arg_recipients){    
    print "Sending message to $recipient... ";
    if(my $smtp = new Net::SMTP($arg_smtp)){
      $smtp->mail("$program\@$host");
      $smtp->to($recipient);
      $smtp->data();
      $smtp->datasend("To: $recipient\n");
      $smtp->datasend("Subject: ALERT - $host DISK SPACE GETTING LOW\n");
      $smtp->datasend("\n");
      $smtp->datasend("\n$autoMsg\n  $recipListMsg\n\n$message");
      $smtp->dataend();
      $smtp->quit();
      print "successful";
      push @eventLogStrings, "  = $program sent email to $recipient"
        if($opt_eventLog);
    } else {
      print "failed";
      push @eventLogStrings, "ERROR  = $program failed to email $recipient ="
        if($opt_eventLog);
    }
    print "\n";
  }
}


 ## WRAP IT UP ##
END{
  my @verMsg = (
    "\nVersions info:",
    "  Win32::AdminMisc         $Win32::AdminMisc::VERSION",
    "  Win32::EventLog          $Win32::EventLog::VERSION",
    "  POSIX                    $POSIX::VERSION",
    "  Net::SMTP                $Net::SMTP::VERSION",
    "  File::Spec               $File::Spec::VERSION",
    "  Getopt::Long             $Getopt::Long::VERSION",
    "  Pod::Usage               $Pod::Usage::VERSION",
    "  Perl                     $]",
    "  wdf.pl                   $VERSION",
    "  $^O",
  );
  tie my %winVer, "Tie::IxHash";
  %winVer = Win32::AdminMisc::GetWinVersion;
  for my $key (keys %winVer) {
    push @verMsg, "    $key - $winVer{$key}";
    }
  my $verMsg = join("\n", @verMsg);
  print $verMsg if($opt_versions);


  ## OPTIONAL EVENT LOGGING ##
  if($opt_eventLog){
    push @eventLogStrings, "  = $program run complete =";
    my $strings = join("\n", @eventLogStrings);
    my $eventType =
      @lowDrives > 0 ?'EVENTLOG_WARNING_TYPE':'EVENTLOG_INFORMATION_TYPE';
    Win32::EventLog::Open( my $event )
      or warn 'fail on Win32::EventLog::Open()';
    $event->Report({
      Computer  => $host,
      Source    => $program,
      EventType => $eventType,                                 ## FIXME ##
      Strings   => "\n\n$strings\n$verMsg",
    }) or warn 'fail on Win32::EventLog::Report()';
    ## $event->Close or warn 'fail on Win32::EventLog::Close'; ## FIXME ##
  }
}

##########################################################################
# Round long-decimal numbers for legibility:
# (from Math::Round source)
sub Round {
  my $halfhex = unpack('H*', pack('d', 0.5));
  my $half    = unpack('d',pack('H*', $halfhex));
  my $x;
  my @res = ();
  for $x (@_) {
    if ($x >= 0) { push @res, POSIX::floor($x + $half);
    } else {       push @res, POSIX::ceil ($x - $half);
    }
  }
  return (wantarray) ? @res : $res[0];
}
##########################################################################
# Insert commas in long numbers for legibility:
sub Commify {
  my @output;
  for(@_){
    my $input = $_;
    $input = reverse $input;
    $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
    $input = reverse $input;
    push @output, $input;
  }
  return @output;
}
##########################################################################


=head1 TITLE

wdf.pl - Check free disk space of all hard disks on a Win32 localhost

=head1 SYNOPSIS

 wdf <arguments> <options>

 eg; wdf.pl --versions --lowFree 15 --recipient pastor@church.org

 Arguments and options may be called by short or long form, or even mixed
 eg;
   wdf --lowFree 5 --recipient admin@church.org --smtp mail.church.org
   wdf -l 5 -r admin@church.org -s mail.church.org
   wdf -l 5 --recipient admin@church.org -s mail.church.org

 Arguments accept an optional '='
 eg;
   wdf -lowFree=30
   wdf -lowFree 30

=head1 DESCRIPTION

Check free disk space of all hard disks on Win32 locallhost.
Optional email notification on low free space.
Optional Event Log entry on program run.
Intended to run periodically as a scheduled task.

=head1 ARGUMENTS

 --lowFree <positive_integer>
 --recipient <valid_email_address>
 --smtp <nearby_SMTP_server>

 "lowFree" is the minimum percentage of free disk space to check for.
 If there is less free space than this, print to console
 and optionally send email alert.

 "recipient" is the email address to send alert message to.
 Accepts only one argument, but can be specified multiple times:
 eg;  wdf -r pastor@church.org -r officemgr@church.org

 "smtp" is an IP address or name of a nearby SMTP server.
 Default value of localhost.

=head1 OPTIONS

 --eventlog   report results to Win32 Event Log
 --versions   print Modules, Perl, OS, Program info
 --help       print contents of pod USAGE, ARGUMENTS, OPTIONS
 --man        print pod in it's entiretya

=head1 WIN32 NOTES

 assoc .pl=Perl
 ftype Perl=c:\perl\bin\perl.exe "%1" %*
 pathext=.pl;
 path=c:\perl\bin\;

 ppm set repository ROTH http://www.roth.net/perl/packages
 ppm set save
 ppm install Win32-AdminMisc

 Login as administrator
 control panel, scheduler, runas specific_user

 at 06:00 /every:Th c:\perl\bin\perl.exe c:\perls\wdf.pl -e -l 25 -r user@host.dom

 pl2bat wdf.pl

=head1 SMTP NOTES

 telnet mailserver.dom.tld 25
 220 mailserver.dom.tld ESMTP
 helo client.dom.tld
 250 OK
 mail from: user1@dom.tld
 250 Sender OK
 rcpt to: user2@dom.tld
 250 Recipient OK
 testing, testing, 1... 2... 3
 .
 250 Message accepted for deliver
 quit
 221 mailserver.dom.tld closing connection

=head1 TESTED

 OS               Win2kPro sp2
                  NT4.0 sp6
 Perl             ActivePerl 5.6.1
 Win32::AdminMisc 20000708
 POSIX            1.03
 Net::SMTP        2.19
 File::Spec       0.82
 Pod::Usage       1.14
 Getopt::Long     2.25

=head1 AUTHOR

ybiC

=head1 CREDITS

 Thanks to:
  thunders for join() tip,
  Kanji for pointing out 0-bytes-free bug of 'if($total && $free){...}',
  fsn for mondo SMTP info/tips/help,
  Dave Roth for writing Win32 Perl (Scripting|Programming) books.
  And to some guy named vroom

=head1 TODO

   Confirm NT 'at' entries remain after reboot
   Debug specified-EventType-ignored, 'none' shown by EventViewer
   Debug NT4-eventlog-no-line-endings
   Debug 'fail on Win32::EventLog::Close'
   Provide Message.dll for message table (Win32::EventLog::Message)
     use Win32::EventLog::Message;
     RegisterSource( 'System', 'My Perl Source' );
       $Event->Report( {
          EventID     => EVENT_ID,
          Strings     => "Everything is okay.\nReally, it's okay.",
          EventType   => EVENTLOG_SUCCESS_TYPE,
       });
     UnRegisterSource( 'System', 'My Perl Source' );
   More informative Net::SMTP errors

=head1 UPDATES

 2002-07-13   21:50 CDT
   Initial working code

 2002-07-19   10:05 CDT
   Rework email notify for standard Net::SMTP instead of Mail::Sender
   Programatically include server name in message
   Debug email notification (bad sender format)
   Debug email subject naming smtp host as having low drive space
   Strip dir path from $0 (down to just wdf.pl)
   Unshift $alarum into @message before join-ing @message into $message
   Borrow code from Math::Round for Round()
   Borrow code from Sys::Hostname for hostName()
   Getopt::Long and Pod::Usage
   Debug program continues to run even if required args not provided
   Eliminate $opt_useMail.  Instead, check for @recipient
   Protect against divide-by-zero from potential drive problem
     if($total && $free){...}
   Win32::AdminMisc::GetDrives(DRIVE_FIXED) instead of @arg_drives
   Win32::AdminMisc::GetComputerName() instead of hostName()
   Check for $arg_lowFree to be *positive* number
   Post to PerlMonks Code Catacombs, requesting PERL-ectomy
   Squash 0-bytes-free bug
     replace 'if($total && $free){...}'
     with 'next unless $total;'
   Intelligent singular/plural on 'less than n% free' message
   Event Log of program start, message, notify and completion
   Test from Win2k 'at' and Task Scheduler (success)
   Unsubify eventLog(), combine all into one message
   Eliminate 'uninit value' from 'pod2usage(...) unless $arg_lowFree > 0'
   Event Log of per-user email success/fail
   Test on church NT4+Exchange server
   Test from WinNT4 'at' (success)
   Getopt argument for nearest SMTP server, default of localhost

=cut
