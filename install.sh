#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          apt-get -y install puppet git
          ;;
     GENTOO)
          emerege --sync
          emerge -n app-admin/puppet dev-vcs/git
          ;; 
     *)
          echo "This Distribution is not supported."
          ;;
esac

puppet module install puppetlabs-stdlib

mkdir /root/benchmark
cd /root/benchmark/
git clone git@gitlab.syseleven.de:t.lohner/benchmark.git