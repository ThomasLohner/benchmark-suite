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
    $root_my_cnf = '/root/.my.cnf'

    # add percona apt repo
    include apt
    apt_key {'percona':
      ensure => present,
      id     => '1C4CBDCDCD2EFD2A',
      server => 'keys.gnupg.net',
    }
    apt::source {'percona':
      location    => 'http://repo.percona.com/apt',
      release     => $::lsbdistcodename,
      repos       => 'main',
      include_src => true,
      include_deb => true,
      require     => Apt_key['percona'],
      before      => Package[$packages],
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
