class deployment::museumpas (
  $config_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'museumpas-website':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  package { 'museumpas-data':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'museumpas-website-config':
    ensure  => 'file',
    path    => '/var/www/museumpas/.env',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[museumpas-website]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  exec { 'import museumpas database dump':
    command   => "mysql ${db_name} < /data/museumpas/db.sql",
    path      => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe => Package['museumpas-data'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    require   => [ File['museumpas-website-config'], Class['mysql::server'] ],
    noop      => $noop_deploy
  }

  exec { 'run museumpas database migrations':
    command   => 'php artisan migrate',
    cwd       => '/var/www/museumpas',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe => Package['museumpas-website'],
    require   => [ File['museumpas-website-config'], Exec['import museumpas database dump'] ],
    noop      => $noop_deploy
  }

  exec { 'composer script post-create-project-cmd':
    command     => 'vendor/bin/composer run-script post-create-project-cmd',
    cwd         => '/var/www/museumpas',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/museumpas'],
    environment => [ 'HOME=/root'],
    subscribe   => Package['museumpas-website'],
    require     => File['museumpas-website-config'],
    noop        => $noop_deploy
  }

  exec { 'composer script post-autoload-dump':
    command     => 'vendor/bin/composer run-script post-autoload-dump',
    cwd         => '/var/www/museumpas',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/museumpas'],
    environment => [ 'HOME=/root'],
    subscribe   => Package['museumpas-website'],
    require     => [ File['museumpas-website-config'], Exec['composer script post-create-project-cmd'] ],
    noop        => $noop_deploy
  }

  exec { 'clear museumpas cache':
    command   => 'php artisan cache:clear',
    cwd       => '/var/www/museumpas',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe => Package['museumpas-website'],
    require   => [ File['museumpas-website-config'], Exec['composer script post-autoload-dump'] ],
    noop      => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts museumpas':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[museumpas-website]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::museumpas']
}
