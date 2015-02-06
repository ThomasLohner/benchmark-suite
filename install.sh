#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          wait
          apt-get -y install puppet git
          wait
          ;;
     GENTOO)
          emerege --sync
          wait
          emerge -n app-admin/puppet dev-vcs/git
          wait
          ;; 
     *)
          echo "This Distribution is not supported."
          ;;
esac

puppet module install puppetlabs-stdlib

cd /root/
git clone http://gitlab.syseleven.de/t.lohner/benchmark.git