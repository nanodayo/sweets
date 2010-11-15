#!/usr/bin/perl

use Socket;

$host = "127.0.0.1";
$port = "10000";
$message = "exit";

$count = 0;

foreach $i (@ARGV) {
	if($i eq "-help") {
		&usage();
	} elsif($i eq "-h") {
		$host = @ARGV[$count+1];
	} elsif($i eq "-p") {
		$port = @ARGV[$count+1];
	} elsif($i eq "-m") {
		$message = @ARGV[$count+1];
	}
	$count++;
}

$addr = inet_aton($host)
	or die "inet_aton error!\n";

$sock_addr = pack_sockaddr_in($port, $addr);

socket(SOCK, PF_INET, SOCK_STREAM, 0)
	or die "socket error!\n";

connect(SOCK, $sock_addr)
	or die "connect error!\n";

select(SOCK); $|=1; select(STDOUT);

print SOCK "$message\n";
$buf=<SOCK>;
print $buf;

close(SOCK);

exit;

sub usage {
	print <<END_OF_DATA;

usage:
 perl tcp_writer.pl <option> <value>...

-m message
-h target host
-p target port
-help help

END_OF_DATA

	exit;
}