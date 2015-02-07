# generate randmon mysql root password
$mysql_root_pw = generate('/usr/bin/pwgen', '12', '1')

case $::operatingsystem {
  'gentoo': {

    $packages    = 'dev-db/percona-server'
    $service     = 'mysql'
    $root_my_cnf = '/root/.my.cnf'

    # configure keywords and useflags
    file_line { 'mysql_keywords':
      path   => '/etc/portage/package.keywords',
      line   => 'dev-db/percona-server ~amd64',
      match  => '^dev-db/percona-server',
      before => Package[$packages],
    }
    file_line { 'mysql_use':
      path  => '/etc/portage/package.use',
      line  => 'dev-db/percona-server jemalloc',
      match => '^dev-db/percona-server',
      before => Package[$packages],
    }
    # initial setup of /var/lib/mysql and setting mysql root pass
    exec {'mysql_setup':
      command     => "/usr/bin/emerge --config $packages",
      creates     => '/var/lib/mysql/mysql',
      refreshonly => true,
      require => [File[$root_my_cnf],Package[$packages]],
      notify  => Service[$service],
    }

  }
  'ubuntu': {

    $packages    = ['percona-server-server-5.6']
    $service     = 'mysql'
    $root_my_cnf = '/home/ubuntu/.my.cnf'

    # add percona apt repo
    exec {'percona_apt_repo':
      command => '/usr/bin/apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A',        
      unless  => '/usr/bin/apt-key list | /bin/grep 1024D/CD2EFD2A',
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
      before  => Package[$packages],
    }
    # set mysql root password
    exec {'mysql_setup':
      command     => "/usr/bin/mysqladmin password $mysql_root_pw",
      refreshonly => true,
      require     => File[$root_my_cnf],
      notify      => Service[$service],
    }

  }
  default: {
    fail("Unknown OS: $::operatingsystem")
  }
}

file {$root_my_cnf:
  content => "[client]\nuser=root\npassword=$mysql_root_pw",
  replace => false,
  notify  => Exec['mysql_setup'],
  mode    => 0600,
}

# disable query_cache
file_line {'query_cache_size':
  path    => '/etc/mysql/my.cnf',
  after   => '[mysqld]',
  line    => "query_cache_size = 0",
  match   => "^query_cache_size",
  notify  => Service[$service],
  require => Package[$packages],
}
file_line {'query_cache_type':
  path  => '/etc/mysql/my.cnf',
  after => '[mysqld]',
  line  => "query_cache_type = 0",
  match => "^query_cache_type",
  notify => Service[$service],
  require => Package[$packages],
}

# make mysql listen on all ip addresses
file_line {'bind_address':
  path  => '/etc/mysql/my.cnf',
  line  => "bind-address = *",
  match => "^bind-address",
  notify => Service[$service],
  require => Package[$packages],
}

package {$packages:
  ensure => installed,
  notify => Service[$service],
}

service {$service:
  ensure  => running,
  enable  => true,
}
