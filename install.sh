#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          apt-get -y install puppet
          ;;
     GENTOO)
          emerege --sync
          emerge -n puppet
          ;; 
     *)
          echo "This Distribution is not supported."
          ;;
esac

puppet module install puppetlabs-stdlib