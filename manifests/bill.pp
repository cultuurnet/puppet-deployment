class deployment::bill (
  $db_name,
  $config_source,
  $license_source,
  $robots_source = undef,
  $htaccess_source = undef,
  $project_prefix = 'bill',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  $basedir = '/var/www/bill'

  contain ::deployment

  package { 'bill-website':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'bill-database':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'bill-files':
    ensure  => 'latest',
    require => Package['bill-website'],
    noop    => $noop_deploy
  }

  file { 'bill-website-config':
    ensure  => 'file',
    path    => "${basedir}/.env",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['bill-website'],
    noop    => $noop_deploy
  }

  file { 'bill-license':
    ensure  => 'file',
    path    => "${basedir}/config/license.key",
    source  => $license_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['bill-website'],
    noop    => $noop_deploy
  }

  if $robots_source {
    file { 'bill-robots.txt':
      ensure  => 'file',
      path    => "${basedir}/web/robots.txt",
      source  => $robots_source,
      owner   => 'www-data',
      group   => 'www-data',
      require => Package['bill-website'],
      noop    => $noop_deploy
    }
  }

  if $htaccess_source {
    file { 'bill-htaccess':
      ensure  => 'file',
      path    => "${basedir}/web/.htaccess",
      source  => $htaccess_source,
      owner   => 'www-data',
      group   => 'www-data',
      require => Package['bill-website'],
      noop    => $noop_deploy
    }
  }

  exec { 'import BILL database dump':
    command   => "mysql --defaults-extra-file=/root/.my.cnf ${db_name} < /data/bill/db.sql",
    path      => [ '/usr/local/bin', '/usr/bin', '/bin'],
    logoutput => true,
    subscribe => Package['bill-database'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    require   => File['bill-website-config'],
    noop      => $noop_deploy
  }

  exec { 'run BILL database migrations':
    command     => 'craft migrate/all',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => Package['bill-website'],
    refreshonly => true,
    require     => File['bill-website-config'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'bill-website'],
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::bill']
}
