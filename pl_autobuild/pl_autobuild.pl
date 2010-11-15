#!/usr/bin/perl

use Socket;
use Sys::Hostname;
use Class::Struct;

# 変数定義

struct PLnode => {
	id	=> '$',
	name	=> '$',
	mgaddr	=> '$',
	exaddr	=> '$',
	mgifname	=> '$',
	exifname	=> '$',
	mgmac	=> '$',
	exmac	=> '$',
	swport	=> '$'
};

# 施設関係
$ermuser = "JAIST";
$ermpass = "plpl";
$ermproj = "plonsb-09";

$ermhost = "172.16.2.241";
$ermport = "1234";

$swmghost = "172.16.2.241";
$swmgport = "1240";

$dmanhost = "172.16.2.241";
$dmanport = "1236";

$tftp_server = "172.16.2.241";
$tftp_dir = "plonsb-09/";

# SCP
$put_proto = "scp";
$scp_user = "guest";
$scp_dir = "/tftpboot/" . "$tftp_dir";
$scp_key = "tftp_guest";

# PLC関係
$plcaddr = "192.168.0.253";
$myhost = hostname();
@tmp = split(/\./ ,$myhost);
$plchost = @tmp[0];
$plcswport = "";
$domain = ".nanodayo.org";
$exsubdomain = ".ex";
$mgsubdomain = ".mg";

# 実験ネットワーク用IP
$netaddr = "192.168.0.";
$ipaddr_count_file = "tmp/count";

# ノードリスト関係
$nodelist_file = "tmp/nodelist.txt";
$plnodelist_file = "tmp/plnodelist.txt";
$dhcpdlist_file = "tmp/dhcpd.list";

@info = ();
@plnode = ();

# 空白対策
$default_mgifname = "eth0";
$default_exifname = "eth1";

# 引数
$num = $ARGV[0];
$is_manage = $ARGV[1];

# vlan関係
$vlan_id = "";
$vlan_buf = "";
$vlan_file = "tmp/vlan_file";

# wolagent定義
$wolagent_a = "172.16.1.253";
$wolagent_aport = "5901";
$wolagent_b = "172.16.1.253";
$wolagent_bport = "5901";
$wolagent_c = "172.16.2.1";
$wolagent_cport = "5903";
$wolagent_d = "172.16.3.253";
$wolagent_dport = "5903";
$wolagent_e = "172.16.3.253";
$wolagent_eport = "5903";
$wolagent_f = "172.16.4.253";
$wolagent_fport = "5904";
$wolagent_g = "172.16.5.253";
$wolagent_gport = "5905";

$wolagent = "172.16.2.241";
$wolagent_port = "5902";

# プログラムのパス
$path = "/root/bin/";

open(LIST, "> $nodelist_file");

#main

#リソースの確保

# リソースの確保
$ermaddr = inet_aton($ermhost)
	or die "inet_aton error!\n";

$ermsock_addr = pack_sockaddr_in($ermport, $ermaddr);

socket(ERMSOCK, PF_INET, SOCK_STREAM, 0)
	or die "socket error!\n";

connect(ERMSOCK, $ermsock_addr)
	or die "connect error!\n";

select(ERMSOCK); $|=1; select(STDOUT);

$i = 0;

print ERMSOCK "USER $ermuser\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "PASSWD $ermpass\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "PROJECT $ermproj\n";
$buf=<ERMSOCK>;
print $buf;

#PLCホストの情報を取得
print ERMSOCK "HOLD node $plchost\n";
$buf=<ERMSOCK>;
print $buf;
print ERMSOCK "INFO node $plchost\n";
while ($buf = <ERMSOCK>) {
	if($buf eq ".\r\n") {
		last;
#	} elsif($buf =~ /MAC/ && $buf =~ /type\=experiment/) {
	} elsif($buf =~ /type\=experiment/) {
		@info = split(/\'/ ,$buf);
		print "$info[1]\n";
		$plcswport = $info[3];
		print "PLC swport is $info[3]\n";
	}
}

#ノード確保
print ERMSOCK "FINDHOLD node num=$num\n";
while ($buf = <ERMSOCK>) {
	if($buf eq ".\r\n") {
		last;
	} elsif($buf =~ /^420/) {
		print $buf;
		exit;
	} elsif($buf =~ /^201/) {
		print $buf;
	} else {
		print "Node is $buf \n";
		$buf =~ s/\x0D?\x0A?$//; # 改行除去
#		print(LIST "$buf\n");
		$plnode[$i] = new PLnode();
		$plnode[$i]->{name} = $buf;
		$i++;
	}
}

print "$i node hold\n"; # デバッグ用
print "FINDHOLD finished\n"; # デバッグ用

# MACアドレスの取得
foreach $node (@plnode) {
	#$node = $nodelist[$j];
	$flag = 0;
	print ERMSOCK "INFO node $node->{name}";
	print "INFO node $node->{name}\n";
	while ($info_buf = <ERMSOCK>) {
		if($info_buf eq ".\r\n") {
			last;
		} elsif($info_buf =~ /MAC/ && $info_buf =~ /type\=manage/) {
			@info = split(/\'/ ,$info_buf);
			$node->{mgmac} = $info[1];
			$node->{mgifname} = $info[7];
			if($node->{mgifname} eq "") {
				$node->{mgifname} = $default_mgifname;
			}
			print "debug: mgifname is $node->{mgifname}\n";
			print "debug: manage mac addr is $node->{mgmac}\n";
			@info = split(/\=/ ,$info_buf);
			@tmp = split(/ /, $info[5]);
			$node->{mgaddr} = $tmp[0];
			print "manage IP addr is $node->{mgaddr}\n";
		} elsif($info_buf =~ /MAC/ && $info_buf =~ /type\=experiment/ && $flag == "0") {
			@info = split(/\'/ ,$info_buf);
			print "$info[1]\n";
			$node->{exmac} = $info[1];
			$node->{swport} = $info[3];
			$node->{exifname} = $info[7];
			if($node->{exifname} eq "") {
				$node->{exifname} = $default_exifname;
			}
			print "debug: exifname is $node->{exifname}\n";
			print "debug: swport is $info[3]\n";
			print(LIST $node->{name} . $domain . " " . $node->{exmac} . "\n");
			$flag = 1;
		}
	}
}

open(VLAN, "< $vlan_file");
$vlan_id = int(<VLAN>);
close(VLAN)

unless( $vlan_id > 0 && $vlan_id < 4096 ) {
	$vlan_id = 0;
}

if($vlan_id == 0) {
	print ERMSOCK "FINDHOLD vlan num=1\n";
	while($vlan_buf = <ERMSOCK> ) {
		if($vlan_buf eq ".\r\n") {
			last;
		} elsif($vlan_buf =~ /modified/) {
			last;
		} elsif($vlan_buf =~ /"no matched"/) {
			last;
		}
		print "vlan_buf is $vlan_buf\n";
		$vlan_id = $vlan_buf;
		$vlan_id =~ s/\x0D?\x0A?$//; # 改行除去
	}
} else {
	print ERMSOCK "HOLD vlan $vlan_id\n";
	$buf = <ERMSOCK>;
}

open(VLAN, "> $vlan_file");
print VLAN "$vlan_id";
close(VLAN);

print "VLAN ID $vlan_id HOLD\n";

# VLAN設定

print "HOLD swport\n";
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

foreach $node (@plnode) {
	print ERMSOCK "HOLD swport $node->{swport}\n";
	$buf=<ERMSOCK>;
	print $buf;
	print SWMGSOCK "JOINVLAN $vlan_id $node->{swport}\n";
	$buf=<SWMGSOCK>;
	print $buf;
}

print SWMGSOCK "QUIT\n";
close(SWMGSOCK);

print ERMSOCK "RELEASE vlan $vlan_id\n";
$buf=<ERMSOCK>;
print $buf;

# VLAN HOLD is end.
# node add to plc

# $confdir = "/plc/root/var/www/html/pxe_conf"; #もう使わない
$site_id = 1;

# もう使わない
# if(!-d $confdir){
#	mkdir $confdir;
# }

open(COUNT, "< $ipaddr_count_file");
$count = int(<COUNT>);
close(COUNT);

unless( $count > 0 && $count < 253 ) {
	$count = 0;
}

foreach $node (@plnode) {
	$count++;
	$addr = $netaddr . $count;

	print "host is $node->{name}\n";
	$nodename = $node->{name} . $domain;
	$nodemgname = $node->{name} . $mgsubdomain . $domain;
	$node->{exaddr} = $addr;
	open(NODECONF, "> $node->{name}");
	open(ADDER_RESULT,"python $path/pl_nodeadder.py -n $nodename -a $node->{exaddr} -m $node->{exmac} -i $node->{exifname} -e |");
	while($buf = <ADDER_RESULT>) {
		print NODECONF "$buf";
	}
	close(ADDER_RESULT);
	close(NODECONF);

	open(MG_ADDER,"python $path/pl_expifadder.py -n $nodename -a $node->{mgaddr} -m $node->{mgmac} -h $nodemgname -i $node->{mgifname} -v $vlan_id -mg |");
	close(MG_ADDER);
	open(CONF_TO_IMG,"bash $path/pl_conf_to_img.sh $node->{name} $plchost $tftp_dir |");
	close(CONF_TO_IMG);
}

open(COUNT, "> $ipaddr_count_file");
print COUNT "$count";
close(COUNT);

# sleep(5);

# DHCPサーバの構築

open(DHCPLIST, "+>> $dhcpdlist_file");
foreach $node (@plnode) {
	chomp($node->{exaddr});
	print DHCPLIST "$node->{name} $node->{exmac} $node->{exaddr}\n";
}

close(DHCPLIST);
system("perl", "$path/dhcpd_conf_gen.pl", "-f", "$dhcpdlist_file" ); 
system("service", "dhcpd", "restart");

# DMAN用ソケット

# $confpath = "nanodayo/pxelinux.cfg/" . "$plchost" . ".conf"; # もう使わない

$dmanaddr = inet_aton($dmanhost)
	or die "inet_aton error!\n";

$dmansock_addr = pack_sockaddr_in($dmanport, $dmanaddr);

socket(DMANSOCK, PF_INET, SOCK_STREAM, 0)
	or die "socket error!\n";

connect(DMANSOCK, $dmansock_addr)
	or die "connect error!\n";

select(DMANSOCK); $|=1; select(STDOUT);

# アップロード＆リンク張替え
foreach $node (@plnode) {
	$pxe = $node->{name} . ".pxe";
	@tmpaddr = split(/\./,$node->{mgaddr});
	$pxeconf = sprintf("pxelinux.cfg/%02X%02X%02X%02X", $tmpaddr[0],$tmpaddr[1],$tmpaddr[2],$tmpaddr[3]);
	print "send to dman : SYMLINK $pxe pxelinux.0\n";
	# ToDo:confファイルを切り替える
	$imgfile = "$node->{name}.img";
	$confpath = $node->{name} . "_X_". "$plchost" . ".pxeconf";
	if($put_proto eq "tftp") {
		$destdir = "$tftp_dir" . "$imgfile";
		system('tftp',"$tftp_server",'-c','put',"$imgfile","$destdir");
		$destdir = "$tftp_dir" . "$confpath";
		system('tftp',"$tftp_server",'-c','put',"$confpath","$destdir");
	} elsif($put_proto eq "scp") {
		$destdir = "$tftp_dir" . "$confpath";
		system('scp','-i',"$scp_key","$confpath","$scp_user\@$tftp_server:$scp_dir");
		system('scp','-i',"$scp_key","$imgfile","$scp_user\@$tftp_server:$scp_dir");
	}

	print DMANSOCK "SYMLINK $pxe pxelinux.0\n";
	$buf=<DMANSOCK>;
	print $buf;
	print "send to dman : SYMLINK $pxeconf $destdir\n";
	print DMANSOCK "SYMLINK $pxeconf $destdir\n";
	$buf=<DMANSOCK>;
	print $buf;
}

close(DMANSOCK);

# ノードの起動
foreach $node (@plnode) {
#	&wol_send($node->{name}, $node->{mgmac});
}

# ファイルへの書き出し
open(PLNODELIST, "+>> $plnodelist_file");
foreach $node (@plnode) {
	print PLNODELIST "$node->{id} ";
	print PLNODELIST "$node->{name} ";
	print PLNODELIST "$node->{mgaddr} ";
	print PLNODELIST "$node->{exaddr} ";
	print PLNODELIST "$node->{mgifname} ";
	print PLNODELIST "$node->{exifname} ";
	print PLNODELIST "$node->{mgmac} ";
	print PLNODELIST "$node->{exmac} ";
	print PLNODELIST "$node->{swport}\n";
}
close(PLNODELIST);

# おしまい
print ERMSOCK "QUIT\n";
close(ERMSOCK);
print "socket close\n";
close(LIST);

sub wol_send {
	($node,$mac) = @_;
#	$wolagent = "";
#	$wolagent_port = 0;

	print ("wol_send: node is $node \n");
	print ("wol_send: mac is $mac \n");
	if($node =~ /sintcla/) {
		$wolagent = $wolagent_a;
		$wolagent_port = $wolagent_aport;
	} elsif($node =~ /sintclb/) {
		$wolagent = $wolagent_b;
		$wolagent_port = $wolagent_bport;
	} elsif($node =~ /sintclc/) {
		$wolagent = $wolagent_c;
		$wolagent_port = $wolagent_cport;
	} elsif($node =~ /sintcld/) {
		$wolagent = $wolagent_d;
		$wolagent_port = $wolagent_dport;
	} elsif($node =~ /sintcle/) {
		$wolagent = $wolagent_e;
		$wolagent_port = $wolagent_eport;
	} elsif($node =~ /sintclf/) {
		$wolagent = $wolagent_f;
		$wolagent_port = $wolagent_fport;
	} elsif($node =~ /sintclg/) {
		$wolagent = $wolagent_g;
		$wolagent_port = $wolagent_gport;
	}

	print("wol_send: wolagent is $wolagent\n");
	print("wol_send: wolagent port is $wolagent_port\n");
	$wolagent_addr = inet_aton($wolagent)
		or die "inet_aton error!\n";

	$wolsock_addr = pack_sockaddr_in($wolagent_port, $wolagent_addr);

	socket(WOLSOCK, PF_INET, SOCK_STREAM, 0)
		or die "socket error!\n";

	connect(WOLSOCK, $wolsock_addr)
		or die "connect error!\n";

	print WOLSOCK "$mac\n";
	close(WOLSOCK);
}

