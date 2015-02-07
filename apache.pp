$domainname = 'www.invaliddomain.de'

case $::operatingsystem {
    'gentoo': {

      $packages = ['www-servers/apache','dev-lang/php']
      $apache_service = 'apache2'

      file_line { 'apache_keywords':
        path  => '/etc/portage/package.keywords',
        line  => 'www-servers/apache ~amd64',
        match => '^www-servers/apache',
      }
      file_line { 'apache_use':
        path  => '/etc/portage/package.use',
        line  => 'www-servers/apache -threads apache2_mpms_prefork',
        match => '^www-servers/apache',
      }
      file_line { 'apache_tools_keywords':
        path  => '/etc/portage/package.keywords',
        line  => 'app-admin/apache-tools ~amd64',
        match => '^app-admin/apache-tools',
      }
      file_line { 'apr_keywords':
        path  => '/etc/portage/package.keywords',
        line  => 'dev-libs/apr ~amd64',
        match => '^dev-libs/apr',
      }
      file_line { 'php_keywords':
        path  => '/etc/portage/package.keywords',
        line  => 'dev-lang/php ~amd64',
        match => '^dev-lang/php',
      }
      file_line { 'php_use':
        path  => '/etc/portage/package.use',
        line  => 'dev-lang/php -threads apache2 pdo curl mysqli gd',
        match => '^dev-lang/php',
      }


    }
    'ubuntu', 'debian': {
      $packages = ['apache2']
      $service = 'apache2'
    }
    default: {
      fail("Unknown OS: $::operatingsystem")
    }
}

file_line {'/etc/hosts':
  path => '/etc/hosts',
  line => "$::ipaddress $domainname $::hostname"
}

file { [ "/var/", "/var/www", "/var/www/$domainname/" ]:
  ensure => "directory",
  before => Service[$apache_service],
}

package {$packages:
  ensure => installed,
  before => Service[$apache_service],
}

service {$apache_service:
  ensure  => running,
  enable  => true,
}
