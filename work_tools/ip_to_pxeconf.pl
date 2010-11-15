#!/usr/bin/perl

@tmpaddr = split(/\./,@ARGV[0]);
$pxeconf = sprintf("%02X%02X%02X%02X", $tmpaddr[0],$tmpaddr[1],$tmpaddr[2],$tmpaddr[3]);
print "$pxeconf\n";
