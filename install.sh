#!/bin/bash

DISTR=$(grep -h '^NAME=' /etc/*release | sed -e 's/NAME=//g' | tr -d '[:punct:]' | tr '[a-z]' '[A-Z]')

case $DISTR in
     UBUNTU)
          apt-get update
          apt-get install puppet-common git pwgen python-software-properties cowsay -y
	  APACHEUSER="www-data"
          ;;
     GENTOO)
          emerge --sync
          emerge -n app-admin/puppet dev-vcs/git app-admin/pwgen games-misc/cowsay
          APACHEUSER="apache"
          ;;
     *)
          echo "This Distribution is not supported."
	  exit
          ;;
esac

puppet module install puppetlabs-stdlib

git clone --depth 1 http://gitlab.syseleven.de/t.lohner/benchmark.git /root/benchmark

# link puppet modules to /etc/puppet/modules/
ln -s /root/benchmark/modules/* /etc/puppet/modules/

# apply puppet manifests
puppet apply /root/benchmark/mysql.pp -vv
puppet apply /root/benchmark/apache.pp -vv

# install magento
/root/benchmark/magento.sh $APACHEUSER


