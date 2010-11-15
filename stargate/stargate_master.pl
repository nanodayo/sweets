#!/usr/bin/perl

use Socket;

# 施設関係
$ermuser = "starbed";
$ermpass = "starpass";
$ermproj = "starproj";

$ermhost = "127.0.0.1";
$ermport = "1234";

$swmghost = "127.0.0.1";
$swmgport = "1240";

$nat_vlan = "822";

$flag = $ARGV[0];
$peer = $ARGV[1];
$node = $ARGV[2];
$ifname = $ARGV[3];
$is_static = $ARGV[4];
$static_addr = $ARGV[5];

$slave = '/usr/local/stargate/bin/stargate_slave.pl';
$peerpath = '/usr/local/stargate/etc/peers/';

$domain = ".nanodayo.org";

# local/global判定
if($flag eq '-g') {
	$vlan = $nat_vlan;
} elsif($flag eq '-l') {
	$vlan = $peer;
}

# nodeの確保

## ERM用socket
$ermaddr = inet_aton($ermhost)
	or die "inet_aton error!\n";

$ermsock_addr = pack_sockaddr_in($ermport, $ermaddr);

socket(ERMSOCK, PF_INET, SOCK_STREAM, 0)
	or die "socket error!\n";

connect(ERMSOCK, $ermsock_addr)
	or die "connect error!\n";

select(ERMSOCK); $|=1; select(STDOUT);

print ERMSOCK "USER $ermuser\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "PASSWD $ermpass\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "PROJECT $ermproj\n";
$buf=<ERMSOCK>;
print $buf;

## 実験用のIF取得
print ERMSOCK "INFO node $node";
while ($info_buf = <ERMSOCK>) {
	if($info_buf eq ".\r\n") {
		last;
	} elsif($info_buf =~ /type\=experiment/) {
		@info = split(/\'/ ,$info_buf);
		$swport = $info[3];
	}
}

##swmg用socket
$swmgaddr = inet_aton($swmghost)
	or die "inet_aton error!\n";

$swmgsock_addr = pack_sockaddr_in($swmgport, $swmgaddr);

socket(SWMGSOCK, PF_INET, SOCK_STREAM, 0)
	or die "socket error!\n";

connect(SWMGSOCK, $swmgsock_addr)
	or die "connect error!\n";

print "connected swmg\n";
select(SWMGSOCK); $|=1; select(STDOUT);

print SWMGSOCK "USER $ermuser\n";
$buf=<SWMGSOCK>;
print $buf;
print SWMGSOCK "PASSWD $ermpass\n";
$buf=<SWMGSOCK>;
print $buf;
print SWMGSOCK "PROJ $ermproj\n";
$buf=<SWMGSOCK>;
print $buf;

##swmgでのVLAN変更
print ERMSOCK "HOLD swport $swport\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "HOLD vlan $vlan\n";
$buf=<ERMSOCK>;
print $buf;
print SWMGSOCK "JOINVLAN $vlan $swport\n";
$buf=<SWMGSOCK>;
print $buf;
print SWMGSOCK "QUIT\n";
close(SWMGSOCK);

print ERMSOCK "RELEASE node $node\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "RELEASE swport $swport\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "RELEASE vlan $vlan\n";
$buf=<ERMSOCK>;
print $buf;
close(ERMSOCK);

$node = $node . $domain;

if($flag eq '-g') {
	system('perl','/root/bin/l2tpd_conf_gen.pl',"$peer");
	system('scp','-i','/etc/planetlab/root_ssh_key.rsa',"l2tp.conf","$node:/etc/l2tp/l2tp.conf");
	system('scp','-i','/etc/planetlab/root_ssh_key.rsa',"$peerpath/$peer","$node:/etc/ppp/peers/$peer");

} #elsif($flag eq '-l') {
#}
#open(SLAVE,"ssh -i /etc/planetlab/root_ssh_key.rsa $node /root/bin/stargate_slave.pl $flag $peer |");
#while($buf = <SLAVE>) {
#	print $buf;
#}
#close(SLAVE);
system('ssh','-i','/etc/planetlab/root_ssh_key.rsa', "$node","$slave","$flag","$peer","$ifname", "$is_static", "$static_addr");

print "done\n";
#system('/root/bin/plc_dnsrestarter.sh');

exit; # for debug

