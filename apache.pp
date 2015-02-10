$domainname = 'www.invaliddomain.de'

case $::operatingsystem {
  'gentoo': {

    $packages         = ['www-servers/apache','dev-lang/php']
    $apache_service   = 'apache2'
    $user             = 'apache'
    $apache_vhost_dir = '/etc/apache2/vhosts.d'

    file_line { 'apache_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'www-servers/apache ~amd64',
      match => '^www-servers/apache',
      before => Package[$packages],
    }
    file_line { 'apache_use':
      path  => '/etc/portage/package.use',
      line  => 'www-servers/apache -threads apache2_mpms_prefork',
      match => '^www-servers/apache',
      before => Package[$packages],
    }
    file_line { 'apache_tools_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'app-admin/apache-tools ~amd64',
      match => '^app-admin/apache-tools',
      before => Package[$packages],
    }
    file_line { 'apr_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'dev-libs/apr ~amd64',
      match => '^dev-libs/apr',
      before => Package[$packages],
    }
    file_line { 'php_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'dev-lang/php ~amd64',
      match => '^dev-lang/php',
      before => Package[$packages],
    }
    file_line { 'php_use':
      path  => '/etc/portage/package.use',
      line  => 'dev-lang/php calendar exif pcntl mhash wddx apache2 mysqli truetype sysvipc xmlwriter bcmath xmlreader curl fpm sockets zip dba pdo -recode session pcre cli mysql ftp gd xml',
      match => '^dev-lang/php',
      before => Package[$packages],
    }
    file_line { 'php_eselect_use':
      path  => '/etc/portage/package.use',
      line  => 'app-admin/eselect-php apache2',
      match => '^app-admin/eselect-php',
      before => Package[$packages],
    }
    # enable php in apache
    exec{'activate_php':
      command => 'sed -i "/^APACHE2_OPTS=/s:\"$: -D PHP5\":g" /etc/conf.d/apache2',
      onlyif  => 'test 0 -eq $(grep "^APACHE2_OPTS=" /etc/conf.d/apache2 | grep -cw PHP5)',
      path    => '/bin/:/usr/bin/:/usr/sbin/',
      notify  => Service[$apache_service],
      require => Package[$packages],
    }

  }
  'ubuntu', 'debian': {

    $packages         = ['apache2', 'apache2-utils', 'php5', 'php5-mysql', 'php5-gd', 'php5-mcrypt', 'php5-curl']
    $apache_service   = 'apache2'
    $user             = 'www-data'
    $apache_vhost_dir = '/etc/apache2/sites-enabled'

    # add ppa for php 5.6
    include apt
    apt_key { 'ondrej_php56':
      ensure => 'present',
      id     => 'E5267A6C',
    }
    apt::ppa {'ppa:ondrej/php5-5.6': 
      require => Apt_key['ondrej_php56'],
      before  => Package[$packages],
    }

    # enable mod_rewrite
    exec {'enable_mod_rwrite':
      command => '/usr/sbin/a2enmod rewrite',
      unless  => '/usr/sbin/a2query -m rewrite',
      require => Package[$packages],
      notify  => Service[$apache_service],
    }

    # enable php mod_mcrypt
    exec {'enable_mod_mcrypt':
      command => '/usr/sbin/php5enmod mcrypt',
      unless  => '/usr/sbin/php5query -s apache2 -m mcrypt',
      notify  => Service[$apache_service],
      require => Package[$packages],
    }

   # disable broken default vhost
   file {'/etc/apache2/sites-enabled/000-default.conf':
    ensure  => absent,
    require => File['apache_vhost'],
    notify  => Service[$apache_service],
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

# create docroot
file { [ "/var/", "/var/www"]:
  ensure => "directory",
  before => File["/var/www/$domainname/"],
}
file {"/var/www/$domainname/":
  ensure  => "directory",
  owner   => "$user",
  require => Package[$packages],
}
file { "/var/www/$domainname/index.html":
  content => "<h4>SysEleven Benchmark Suite</h4>",
  owner   => $user,
  require => File["/var/www/$domainname/"],
}
# create apache vhost
file {'apache_vhost':
  path    => "$apache_vhost_dir/$domainname.conf",
  content => template('sys11-benchmark/apache_vhost.conf.erb'),
  notify  => Service[$apache_service],
  require => [Package[$packages],File["/var/www/$domainname/"]],
}

package {$packages:
  ensure => installed,
  before => Service[$apache_service],
}

service {$apache_service:
  ensure  => running,
  enable  => true,
  require => Package[$packages],
}
