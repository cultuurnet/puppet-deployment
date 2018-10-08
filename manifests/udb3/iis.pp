class deployment::udb3::iis (
  $silex_config_source,
  $importer_config_source,
  $importer_rootdir,
  $db_name,
  $project_prefix = 'udb3',
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

  file { $importer_rootdir:
    ensure => directory,
    noop   => $noop_deploy
  }

  file { "${importer_rootdir}/process":
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    noop   => $noop_deploy
  }

  file { "${importer_rootdir}/success":
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    noop   => $noop_deploy
  }

  file { "${importer_rootdir}/error":
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    noop   => $noop_deploy
  }

  file { "${importer_rootdir}/invalid":
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    noop   => $noop_deploy
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
    subscribe => [ 'Package[udb3-iis-silex]', 'File[udb3-iis-silex-config]'],
    noop      => $noop_deploy
  }

  exec { 'iis_silex_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-iis-silex',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-iis-silex'],
    onlyif      => 'test -d /var/www/udb-iis-silex/src/Migrations',
    subscribe   => [ 'Package[udb3-iis-silex]', 'File[udb3-iis-silex-config]'],
    require     => 'Exec[iis-silex-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'udb3-iis-silex', 'udb3-iis-importer'],
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::iis']
}
