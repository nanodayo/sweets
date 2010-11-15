#!/usr/bin/perl

# グローバル設定
# $subnet 担当するネットワーク
# $netmask ネットマスク
# $dns DNSサーバ

# 個別設定
# $mac MACアドレス
# $addr アドレス
# $name host名？

# デフォルト値を設定
# 何も指定しなければ192.168.0.0/24で生成

$subnet = "192.168.0.0";
$netmask = "255.255.255.0";
$dns = "192.168.0.253";
$start = "192.168.0.1";
$end = "192.168.0.200"; # 201からはルータやらDNSやらに予約
$range = ""; # 現状未使用
$routers = "192.168.0.254";

$count = 0;

foreach $i (@ARGV) {
	if($i eq "-h") {
		&usage();
	} elsif($i eq "-n") {
		$subnet = @ARGV[$count+1];
	} elsif($i eq "-f") {
		$listfile = @ARGV[$count+1];
	} elsif($i eq "-m") {
		$netmask = @ARGV[$count+1];
	} elsif($i eq "-r") {
		$range =  @ARGV[$count+1];
	} elsif($i eq "-g") {
		$routers = @ARGV[$count+1];
	} elsif($i eq "-d") {
		$dns = @ARGV[$count+1];
	} elsif($i eq "-s") {
		$start = @ARGV[$count+1];
	} elsif($i eq "-e") {
		$end = @ARGV[$count+1];
	}
	$count++;
}

# open file
open(DHCPD,"> /etc/dhcpd.conf");

open(CONF, "$listfile");
@list = <CONF>;

print(DHCPD "# Created by MADAO\n\n");
print(DHCPD "ddns-update-style none;\n\n");

# この辺でファイルから必要なパラメータを読む

# ファイル的に必要になるパラメータ。変数名だけ定義
#
# グローバル設定
# $subnet 担当するネットワーク
# $netmask ネットマスク
# $dns DNSサーバ

# 個別設定
# $mac MACアドレス
# $addr アドレス
# $name host名？

print(DHCPD "subnet $subnet netmask $netmask {\n");
print(DHCPD "\trange $start $end;\n");
print(DHCPD "\toption subnet-mask $netmask;\n");
print(DHCPD "\toption domain-name-servers $dns;\n");
print(DHCPD "\toption routers $routers;\n");
print(DHCPD "}\n");

foreach $i (@list) {
	($name, $mac, $addr ) = split(/\ /, $i);
	chomp($addr);
	print(DHCPD "host $name {\n");
	print(DHCPD "\thardware ethernet $mac;\n");
	$addr =~ s/\x0D?\x0A?$//; # 改行除去
	print(DHCPD "\tfixed-address $addr;\n");
	print(DHCPD "}\n");
}

close(DHCPD);
close(CONF);

sub usage {
	print <<END_OF_DATA;

usage:
 perl dhcpd_conf_gen.pl <option> <value>...

-n network address
-f node list file
-m netmask
-r address range
-g default gateway
-d dns server
-s start of IPaddress range
-e end of IPadress range
-h help

END_OF_DATA

	exit;
}
