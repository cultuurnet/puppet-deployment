class deployment::udb3::silex (
  $config_source,
  $permissions_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $term_mapping_facilities_source,
  $term_mapping_themes_source,
  $term_mapping_types_source,
  $db_name,
  $pubkey_source,
  $pubkey_auth0_source,
  $project_prefix         = 'udb3',
  $event_conclude_ensure  = 'present',
  $event_conclude_hour    = '0',
  $event_conclude_minute  = '0',
  $noop_deploy            = false,
  $puppetdb_url           = undef,
  $excluded_labels_source = undef
) {

  package { 'udb3-silex':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
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

  if $excluded_labels_source {
    file { 'udb3-silex-excluded-labels':
      ensure  => 'file',
      path    => '/var/www/udb-silex/excluded_labels.yml',
      source  => $excluded_labels_source,
      owner   => 'www-data',
      group   => 'www-data',
      require => 'Package[udb3-silex]',
      notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
      noop    => $noop_deploy
    }
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

  file { 'udb3-silex-pubkey-auth0':
    ensure  => 'file',
    path    => '/var/www/udb-silex/public-auth0.pem',
    source  => $pubkey_auth0_source,
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

  deployment::udb3::terms { 'udb3-silex':
    directory                 => '/var/www/udb-silex',
    facilities_mapping_source => $term_mapping_facilities_source,
    themes_mapping_source     => $term_mapping_themes_source,
    types_mapping_source      => $term_mapping_types_source,
    require                   => Package['udb3-silex'],
    notify                    => [ Class['apache::service'], Class['supervisord::service']],
    noop_deploy               => $noop_deploy
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-bulk-label-offer-worker udb3-event-export-worker',
    require       => 'Package[udb3-silex]',
    noop          => $noop_deploy
  }

  exec { 'silex_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-silex',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-silex'],
    subscribe   => 'Package[udb3-silex]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  cron { 'event_conclude':
    ensure  => $event_conclude_ensure,
    command => '/var/www/udb-silex/bin/udb3.php event:conclude',
    require => 'Package[udb3-silex]',
    user    => 'root',
    hour    => $event_conclude_hour,
    minute  => $event_conclude_minute
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-silex',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::silex']
}
