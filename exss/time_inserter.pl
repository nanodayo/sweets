#!/usr/bin/perl

use Time::HiRes;

while($buf = <STDIN>) {
	$now = Time::HiRes::time;
	($wtime, $msec) = split(/\./, $now);
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($wtime);
	$year += 1900;
	$mon++;
	print "$year/$mon/$mday $hour:$min:$sec.$msec $buf";
}

