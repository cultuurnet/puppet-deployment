class deployment::bill (
  $db_name,
  $config_source,
  $robots_source = undef,
  $htaccess_source = undef,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  $basedir = '/var/www/bill'

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

  exec { 'composer script post-autoload-dump':
    command     => 'vendor/bin/composer dump-autoload -o',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
    user        => 'www-data',
    environment => [ 'HOME=/tmp'],
    logoutput   => true,
    subscribe   => Package['bill-website'],
    refreshonly => true,
    require     => File['bill-website-config'],
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts bill':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => Package['bill-website'],
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::bill']
}