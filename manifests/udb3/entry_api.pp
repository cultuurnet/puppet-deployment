class deployment::udb3::entry_api (
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
  $event_conclude_ensure       = 'present',
  $event_conclude_hour         = '0',
  $event_conclude_minute       = '0',
  $noop_deploy                 = false,
  $puppetdb_url                = undef,
  $excluded_labels_source      = undef
) {

  realize Apt::Source['uitdatabank-entry-api']

  $basedir = '/var/www/udb3-backend'

  package { 'uitdatabank-entry-api':
    ensure  => 'latest',
    notify  => [ Class['apache::service'], Class['supervisord::service'], Profiles::Deployment::Versions[$title]],
    require => Apt::Source['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-uploads':
    ensure  => 'directory',
    path    => "${basedir}/web/uploads",
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-downloads':
    ensure  => 'directory',
    path    => "${basedir}/web/downloads",
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-config':
    ensure  => 'file',
    path    => "${basedir}/config.php",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop    => $noop_deploy
  }

  if $excluded_labels_source {
    file { 'uitdatabank-entry-api-excluded-labels':
      ensure  => 'file',
      path    => "${basedir}/config.excluded_labels.php",
      source  => $excluded_labels_source,
      owner   => 'www-data',
      group   => 'www-data',
      require => Package['uitdatabank-entry-api'],
      notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
      noop    => $noop_deploy
    }
  }

  file { 'uitdatabank-entry-api-permissions':
    ensure  => 'file',
    path    => "${basedir}/config.allow_all.php",
    source  => $permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-pubkey':
    ensure  => 'file',
    path    => "${basedir}/public.pem",
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-pubkey-auth0':
    ensure  => 'file',
    path    => "${basedir}/public-auth0.pem",
    source  => $pubkey_auth0_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'uitdatabank-entry-api':
    directory                  => $basedir,
    place_mapping_source       => $externalid_place_mapping_source,
    organizer_mapping_source   => $externalid_organizer_mapping_source,
    place_mapping_filename     => 'config.external_id_mapping_place.php',
    organizer_mapping_filename => 'config.external_id_mapping_organizer.php',
    require                    => Package['uitdatabank-entry-api'],
    notify                     => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop_deploy                => $noop_deploy
  }

  deployment::udb3::terms { 'uitdatabank-entry-api':
    directory                   => $basedir,
    facilities_mapping_source   => $term_mapping_facilities_source,
    themes_mapping_source       => $term_mapping_themes_source,
    types_mapping_source        => $term_mapping_types_source,
    facilities_mapping_filename => 'config.term_mapping_facilities.php',
    themes_mapping_filename     => 'config.term_mapping_themes.php',
    types_mapping_filename      => 'config.term_mapping_types.php',
    require                     => Package['uitdatabank-entry-api'],
    notify                      => [ Class['apache::service'], Class['supervisord::service']],
    noop_deploy                 => $noop_deploy
  }

  logrotate::rule { 'uitdatabank-entry-api':
    path          => "${basedir}/log/*.log",
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
    require       => Package['uitdatabank-entry-api'],
    noop          => $noop_deploy
  }

  exec { 'uitdatabank-entry-api-db-migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
    subscribe   => Package['uitdatabank-entry-api'],
    refreshonly => true,
    noop        => $noop_deploy
  }

  cron { 'uitdatabank-entry-api-event-conclude':
    ensure  => $event_conclude_ensure,
    command => "${basedir}/bin/udb3.php event:conclude",
    require => Package['uitdatabank-entry-api'],
    user    => 'root',
    hour    => $event_conclude_hour,
    minute  => $event_conclude_minute
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::entry_api']
}
