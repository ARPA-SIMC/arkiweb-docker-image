#!/bin/bash
set -eux

yum="yum -y"

sed -i '/^tsflags=/d' /etc/yum.conf

$yum update
$yum install epel-release
$yum install yum-plugin-copr
$yum copr enable simc/arkiweb
$yum install arkiweb httpd

mkdir -p /var/www/html/arkiweb/
cp /usr/share/doc/arkiweb/html/example/index.html /var/www/html/arkiweb/
