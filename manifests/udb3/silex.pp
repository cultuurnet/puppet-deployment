class deployment::udb3::silex (
  $silex_config_source,
  $silex_features_source,
  $silex_permissions_source,
  $angular_app_config_source,
  $angular_app_deploy_config_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $db_name,
  $pubkey_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-silex':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'udb3-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'udb3':
    ensure  => 'latest',
    require => [ 'Package[udb3-silex]', 'Package[udb3-angular-app]' ],
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
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-features':
    ensure  => 'file',
    path    => '/var/www/udb-silex/features.yml',
    source  => $silex_features_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-permissions':
    ensure  => 'file',
    path    => '/var/www/udb-silex/user_permissions.yml',
    source  => $silex_permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-angular-app-config':
    ensure => 'file',
    path   => '/var/www/udb-app/config.json',
    source => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-angular-app]',
    noop    => $noop_deploy
  }

  file { 'udb3-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
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

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/udb-app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[udb3-angular-app]', 'File[udb3-angular-app-config]', 'File[udb3-angular-app-deploy-config]'],
    refreshonly => true,
    notify      => 'Class[Supervisord::Service]',
    noop        => $noop_deploy
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

  exec { 'silex-elasticsearch-migrate':
    command     => 'bin/udb3.php elasticsearch:migrate',
    cwd         => '/var/www/udb-silex',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-silex'],
    subscribe   => 'Package[udb3-silex]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 silex':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::silex']
}
