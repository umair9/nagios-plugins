#!/usr/bin/perl -T
# nagios: -epn
#
#  Author: Hari Sekhon
#  Date: 2015-03-21 16:53:17 +0000 (Sat, 21 Mar 2015)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  vim:ts=4:sts=4:sw=4:et

$DESCRIPTION = "Nagios Plugin to check which is the master node in an Elasticsearch cluster

Optional --node may be specified to check it hasn't changed, raises warning if it has as this may signal a failover event has occured

Tested on Elasticsearch 1.2.1 and 1.4.4";

$VERSION = "0.2";

use strict;
use warnings;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/lib";
}
use HariSekhonUtils;
use HariSekhon::Elasticsearch;

$ua->agent("Hari Sekhon $progname version $main::VERSION");

my $node;

%options = (
    %hostoptions,
    "N|node=s" => [ \$node, "Hostname or IP address of node for which to expect as master, raises warning if a different master node is found to alert us to a possible failover event. Optional" ],
);
push(@usage_order, qw/node/);

get_options();

$host = validate_host($host);
$port = validate_port($port);
$node = validate_host($node, "node") if defined($node);
validate_thresholds(0, 0);

vlog2;
set_timeout();

$status = "OK";

my $url = "/_cat/master";
my $content = curl_elasticsearch_raw $url;

my @parts;
@parts = split(/\s+/, $content, 4);
defined($parts[2]) or quit "UNKNOWN", "failed to find 3rd field in result. $nagios_plugins_support_msg_api";
isIP($parts[2]) or quit "UNKNOWN", "returned non-IP for 3rd field in result. $nagios_plugins_support_msg_api";
my $ip = $parts[2];
isHostname($parts[1]) or quit "UNKNOWN", "returned invalid hostname in 2nd field of result. $nagios_plugins_support_msg_api";
my $node_hostname = $parts[1];

$msg = "elasticsearch ";

$msg .= "master node = '$node_hostname'";
if(defined($node) and not ($node eq $node_hostname or $node eq $ip)){
    $msg .= " [$ip]";
    warning;
    $msg .= " (expected '$node')";
} elsif($verbose){
    $msg .= " [$ip]";
}

vlog2;
quit $status, $msg;
