case $::operatingsystem {
    'gentoo': {

      $packages = ['dev-db/percona-server']
      $service = 'mysql'

      # configure keywords and useflags
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

      # add percona apt repo
      exec {'percona_apt_repo':
        command => '/usr/bin/apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A',        
        before  => Exec['apt-get update'],
      }
      file_line {'percona_deb':
	path   => '/etc/apt/sources.list',
	line   => "deb http://repo.percona.com/apt $::lsbdistcodename main",
	match  => '^deb http://repo.percona.com/apt',
        before => Exec['apt-get update'],
      }
      file_line {'percona_deb-src':
        path   => '/etc/apt/sources.list',
        line   => "deb-src http://repo.percona.com/apt $::lsbdistcodename main",
        match  => '^deb-src http://repo.percona.com/apt',
        before => Exec['apt-get update'], 
      }
      exec {'apt-get update':
        command => '/usr/bin/apt-get update',
      }

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
