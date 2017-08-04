class deployment::udb3::silex (
  $config_source,
  $features_source,
  $permissions_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $db_name,
  $pubkey_source,
  $event_conclude_hour = '0',
  $event_conclude_minute = '0',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-silex':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'udb3-php':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'udb3-silex-log':
    ensure  => 'directory',
    path    => '/var/www/udb-silex/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-silex]',
    noop    => $noop_deploy
  }

  file { 'udb3-media':
    ensure  => 'directory',
    path    => '/var/www/udb-silex/web/media',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    noop    => $noop_deploy
  }

  file { 'udb3-uploads':
    ensure  => 'directory',
    path    => '/var/www/udb-silex/web/uploads',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    noop    => $noop_deploy
  }

  file { 'udb3-downloads':
    ensure  => 'directory',
    path    => '/var/www/udb-silex/web/downloads',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    noop    => $noop_deploy
  }

  file { 'udb3-silex-config':
    ensure  => 'file',
    path    => '/var/www/udb-silex/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-features':
    ensure  => 'file',
    path    => '/var/www/udb-silex/features.yml',
    source  => $features_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-permissions':
    ensure  => 'file',
    path    => '/var/www/udb-silex/user_permissions.yml',
    source  => $permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-pubkey':
    ensure  => 'file',
    path    => '/var/www/udb-silex/public.pem',
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'udb3-silex':
    directory                => '/var/www/udb-silex',
    place_mapping_source     => $externalid_place_mapping_source,
    organizer_mapping_source => $externalid_organizer_mapping_source,
    require                  => 'Package[udb3-silex]',
    notify                   => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop_deploy              => $noop_deploy
  }

  logrotate::rule { 'udb3-silex':
    path          => '/var/www/udb-silex/log/*.log',
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-amqp-listener udb3-search-cache-warmer udb3-worker udb3-bulk-label-offer-worker udb3-event-export-worker',
    require       => 'Package[udb3-silex]',
    noop          => $noop_deploy
  }

  exec { 'silex-db-install':
    command   => 'bin/udb3.php install',
    cwd       => '/var/www/udb-silex',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-silex'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\" and table_name not like \"doctrine_migration_versions\";')",
    subscribe => 'Package[udb3-silex]',
    noop      => $noop_deploy
  }

  exec { 'silex_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-silex',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-silex'],
    subscribe   => 'Package[udb3-silex]',
    require     => 'Exec[silex-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  cron { 'event_conclude':
    command    => '/var/www/udb-silex/bin/udb3.php event:conclude',
    require    => 'Package[udb3-silex]',
    user       => 'root',
    hour       => $event_conclude_hour,
    minute     => $event_conclude_minute
  }

  deployment::versions { $title:
    project      => 'udb3',
    packages     => [ 'udb3-silex', 'udb3-php'],
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::silex']
}
