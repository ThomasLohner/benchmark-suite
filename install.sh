#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          apt-get install puppet git -y
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

cd /root/
git clone --depth 1 http://gitlab.syseleven.de/t.lohner/benchmark.git