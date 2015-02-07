case $::operatingsystem {
    'gentoo': {

      $packages = ['dev-db/percona-server']
      $service = 'mysql'

      file_line { 'mysql_keywords':
        path  => '/etc/portage/package.keywords',
        line  => 'dev-db/percona-server ~amd64',
        match => '^dev-db/percona-server',
      }
      file_line { 'mysql_use':
        path  => '/etc/portage/package.use',
        line  => 'dev-db/percona-server jemalloc',
        match => '^dev-db/percona-server',
      }
      exec {'setup_mysql':
	command => "/usr/bin/emerge --config $packages",
	creates => '/var/lib/mysql/mysql',
        require => Exec['mysql_root_pass'],
	notify  => Service[$service],
      }

    }
    'ubuntu': {

      $packages = ['percona-server-server-5.6']
      $service = 'mysql'

    }
    default: {
      fail("Unknown OS: $::operatingsystem")
    }
}

file_line {'/etc/hosts':
  path  => '/etc/hosts',
  line  => "$::ipaddress $domainname $::hostname",
  match => "^$::ipaddress",
}

exec {'mysql_root_pass':
  command => '/bin/echo -e "[client]\nuser=root\npassword=$(/usr/bin/pwgen 12 1)" > /root/.my.cnf && chmod 600 /root/.my.cnf',
  creates => '/root/.my.cnf',
}

package {$packages:
  ensure => installed,
  notify => Service[$service],
}

service {$service:
  ensure  => running,
  enable  => true,
}
