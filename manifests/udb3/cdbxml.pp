class deployment::udb3::cdbxml (
  $config_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-cdbxml':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  file { 'udb3-cdbxml-config':
    ensure  => 'file',
    path    => '/var/www/udb-cdbxml/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-cdbxml]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-cdbxml-logdir':
    ensure  => 'directory',
    path    => '/var/www/udb-cdbxml/log',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-cdbxml]',
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'udb3-cdbxml':
    directory                => '/var/www/udb-cdbxml',
    place_mapping_source     => $externalid_place_mapping_source,
    organizer_mapping_source => $externalid_organizer_mapping_source,
    require                  => 'Package[udb3-cdbxml]',
    notify                   => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop_deploy              => $noop_deploy
  }

  logrotate::rule { 'udb3-cdbxml':
    path          => '/var/www/udb-cdbxml/log/*.log',
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-cdbxml-service',
    require       => 'File[udb3-cdbxml-logdir]',
    noop          => $noop_deploy
  }

  exec { 'cdbxml-db-install':
    command   => 'bin/app.php install',
    cwd       => '/var/www/udb-cdbxml',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-cdbxml'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\" and table_name not like \"doctrine_migration_versions\";')",
    subscribe => [ 'Package[udb3-cdbxml]', 'File[udb3-cdbxml-config]'],
    noop      => $noop_deploy
  }

  exec { 'cdbxml_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-cdbxml',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-cdbxml'],
    subscribe   => 'Package[udb3-cdbxml]',
    require     => 'Exec[cdbxml-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 cdbxml':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-cdbxml]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::cdbxml']
}
