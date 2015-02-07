#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          apt-get install puppet-common git pwgen -y
          ;;
     GENTOO)
          emerge --sync
          emerge -n app-admin/puppet dev-vcs/git app-admin/pwgen
          ;;
     *)
          echo "This Distribution is not supported."
	  exit
          ;;
esac

puppet module install puppetlabs-stdlib

cd /root/
git clone --depth 1 http://gitlab.syseleven.de/t.lohner/benchmark.git
