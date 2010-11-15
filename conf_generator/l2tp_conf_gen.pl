#!/usr/bin/perl

$peer = "";
$user = "nanodayo";
$password = "yaranaika";

$peer = @ARGV[0];

# open file
open(L2TP,"> l2tp.conf");

print L2TP <<L2TP_CONF;
global

load-handler "sync-pppd.so"
load-handler "cmd.so"

listen-port 1701

section sync-pppd
lac-pppd-opts "call $peer"

section peer
peer $peer

port 1701
lac-handler sync-pppd
lns-handler sync-pppd

section cmd

L2TP_CONF

close(L2TP);
