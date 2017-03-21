class deployment::udb3::iis (
  $silex_config_source,
  $importer_config_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-iis-silex':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  package { 'udb3-iis-importer':
    ensure => 'latest',
    notify => 'Class[Supervisord::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-iis-silex-log':
    ensure  => 'directory',
    path    => '/var/www/udb-iis-silex/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-iis-silex]',
    noop    => $noop_deploy
  }

  file { 'udb3-iis-importer-log':
    ensure  => 'directory',
    path    => '/var/www/udb-iis-importer/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-iis-importer]',
    noop    => $noop_deploy
  }

  file { 'udb3-iis-silex-config':
    ensure  => 'file',
    path    => '/var/www/udb-iis-silex/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-iis-silex]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-iis-importer-config':
    ensure  => 'file',
    path    => '/var/www/udb-iis-importer/config.yml',
    source  => $importer_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-iis-importer]',
    notify  => 'Class[Supervisord::Service]',
    noop    => $noop_deploy
  }

  logrotate::rule { 'udb3-iis-silex':
    path          => '/var/www/udb-iis-silex/log/*.log',
    rotate        => '10',
    rotate_every  => 'day',
    missingok     => true,
    compress      => true,
    delaycompress => true,
    ifempty       => false,
    create        => true,
    create_mode   => '0640',
    create_owner  => 'www-data',
    create_group  => 'www-data',
    sharedscripts => true,
    require       => 'Package[udb3-iis-silex]',
    noop          => $noop_deploy
  }

  logrotate::rule { 'udb3-iis-importer':
    path          => '/var/www/udb-iis-importer/log/*.log',
    rotate        => '10',
    rotate_every  => 'day',
    missingok     => true,
    compress      => true,
    delaycompress => true,
    ifempty       => false,
    create        => true,
    create_mode   => '0640',
    create_owner  => 'www-data',
    create_group  => 'www-data',
    sharedscripts => true,
    require       => 'Package[udb3-iis-importer]',
    noop          => $noop_deploy
  }
  exec { 'iis-silex-db-install':
    command   => 'bin/app.php install',
    cwd       => '/var/www/udb-iis-silex',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-iis-silex'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\" and table_name not like \"doctrine_migration_versions\";')",
    subscribe => 'Package[udb3-iis-silex]',
    noop      => $noop_deploy
  }

  exec { 'iis_silex_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-iis-silex',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-iis-silex'],
    subscribe   => 'Package[udb3-iis-silex]',
    require     => 'Exec[iis-silex-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 iis silex':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::iis']
}
