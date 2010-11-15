#!/usr/bin/perl

use Sys::Hostname;

# 引数
$flag = $ARGV[0];
$peer = $ARGV[1];
#$node = $ARGV[2];
$ifname = $ARGV[2];
$interface = $ARGV[2];
$is_static = $ARGV[3];
$static_addr = $ARGV[4];

open(PLC_CONFIG, "< /etc/planetlab/plc_config");
while($buf = <PLC_CONFIG>) {
	if($buf =~ /PLC_API_HOST/) {
		@tmp = split(/\'/ ,$buf);
		$plchost = $tmp[1];
	}
}
close(PLC_CONFIG);

$plchost = gethostbyname("$plchost");
$plchost = sprintf("%u.%u.%u.%u", unpack("C*", $plchost));

# 各種プログラムのパス
# $getmyifname = "/usr/local/stargate/bin/getmyifname";
$getmyipaddr = "/usr/local/stargate/bin/getmyipaddr";
$stargate_register = "/usr/local/stargate/bin/stargate_register.py";
$l2tpd = "/usr/local/sbin/l2tpd";
$l2tp_control =  "/usr/local/sbin/l2tp-control";

#ifnameがdev????な場合用 いらんかも
if($ifname eq 'devx') {
	open(IFNAME,"$getmyifname dev |");
	@tmp = <IFNAME>;
	$interface = @tmp[0];
	print "expif is $interface\n";
	close(IFNAME);
}

#dhclientを実行 or staticに設定
system('killall','dhclient');
if( $is_static eq '-s' ) {
	open(IFCONFIG, "ifconfig $inter");
} else {
	open(DHCLIENT,"dhclient $interface |");
	while($buf = <DHCLIENT>) {
		print $buf;
	}
}
close(DHCLIENT);

if($flag eq '-g') {
	# peerへの経路を取得
	open(GATE,"ip route get $peer | awk \'{ print \$3; }\' |");
	@tmp = <GATE>;
	$gate = $tmp[0];
	print $gate;
	close(GATE);

	system('route','delete','default');
	open(ROUTE_DEL,"route delete $peer");
	close(ROUTE_DEL);
	system("route","add","$peer","gw","$gate");

	system("l2tp-control",'"exit"');
	open(L2TP,"$l2tpd |");
	@tmp = <L2TP>;
	print @tmp;
	close(L2TP);
	print "l2tpd start...\n";
	print "peer is $peer\n";

	sleep(2);

	open(ID,"l2tp-control \"start-session $peer\" |");
	#@tmp = <ID>;
	#$sid = $tmp[0];
	close(ID);
	$interface = "ppp0";
	sleep(10);

	#PLCへの経路を設定
	open(ROUTE_DEL,"route delete $plchost");
	close(ROUTE_DEL);
	system("route","add","$plchost","gw","$gate");
}

open(NEWADDR,"$getmyipaddr $interface |");
@tmp = <NEWADDR>;
$addr = @tmp[0];
chomp($addr);
print "new addr is $addr\n";
close(NEWADDR);

$node = hostname();
system('python',"$stargate_register","$flag","$peer","$node","$addr","$ifname");

exit;
