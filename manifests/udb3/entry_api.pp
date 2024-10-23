class deployment::udb3::entry_api (
  $config_source,
  $movie_fetcher_config_source,
  $admin_permissions_source,
  $client_permissions_source,
  $completeness_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $term_mapping_facilities_source,
  $term_mapping_themes_source,
  $term_mapping_types_source,
  $pubkey_source,
  $pubkey_auth0_source,
  $pubkey_keycloak_source,
  Boolean    $schedule_movie_fetcher       = false,
  Integer[0] $event_export_worker_count    = 1,
  Boolean    $with_bulk_label_offer_worker = true,
  Boolean    $with_amqp_listener_uitpas    = true,
  $noop_deploy                             = false,
  $puppetdb_url                            = lookup('data::puppet::puppetdb::url', Optional[String], 'first', undef)
) {

  realize Apt::Source['uitdatabank-entry-api']

  $basedir = '/var/www/udb3-backend'

  package { 'uitdatabank-entry-api':
    ensure  => 'latest',
    notify  => [Class['apache::service'], Profiles::Deployment::Versions[$title]],
    require => Apt::Source['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  cron { 'uitdatabank_process_duplicates':
    command     => "${basedir}/bin/udb3.php place:process-duplicates --force",
    environment => ['SHELL=/bin/bash', 'MAILTO=infra@publiq.be'],
    user        => 'www-data',
    minute      => '0',
    hour        => '5',
    monthday    => '*',
    month       => '*',
    weekday     => '1',
    require     => Package['uitdatabank-entry-api']
  }

  cron { 'uitdatabank_movie_fetcher':
    ensure      => $schedule_movie_fetcher ? {
                     true  => 'present',
                     false => 'absent'
                   },
    command     => "${basedir}/bin/udb3.php movies:fetch --force",
    environment => ['SHELL=/bin/bash', 'MAILTO=infra@publiq.be,jonas.verhaeghe@publiq.be'],
    user        => 'www-data',
    minute      => '0',
    hour        => '4',
    monthday    => '*',
    month       => '*',
    weekday     => '1',
    require     => Package['uitdatabank-entry-api']
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
    notify  => Class['apache::service'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-movie-fetcher-config':
    ensure  => 'file',
    path    => "${basedir}/config.kinepolis.php",
    source  => $movie_fetcher_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => Class['apache::service'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-admin-permissions':
    ensure  => 'file',
    path    => "${basedir}/config.allow_all.php",
    source  => $admin_permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => Class['apache::service'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-client-permissions':
    ensure  => 'file',
    path    => "${basedir}/config.client_permissions.php",
    source  => $client_permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => Class['apache::service'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-entry-api-completeness':
    ensure  => 'file',
    path    => "${basedir}/config.completeness.php",
    source  => $completeness_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    notify  => Class['apache::service'],
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

  file { 'uitdatabank-entry-api-pubkey-keycloak':
    ensure  => 'file',
    path    => "${basedir}/public-keycloak.pem",
    source  => $pubkey_keycloak_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['uitdatabank-entry-api'],
    noop    => $noop_deploy
  }

  if $with_amqp_listener_uitpas {
    systemd::unit_file { 'udb3-amqp-listener-uitpas.service':
      content   => template('deployment/udb3/entry_api/udb3-amqp-listener-uitpas.service.erb')
    }

    service { 'udb3-amqp-listener-uitpas':
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      subscribe => [Package['uitdatabank-entry-api'], Systemd::Unit_file['udb3-amqp-listener-uitpas.service'], File['uitdatabank-entry-api-config'], File['uitdatabank-entry-api-admin-permissions'], File['uitdatabank-entry-api-client-permissions'], File['uitdatabank-entry-api-pubkey'], File['uitdatabank-entry-api-pubkey-auth0'], File['uitdatabank-entry-api-pubkey-keycloak'], Deployment::Udb3::Externalid['uitdatabank-entry-api'], Deployment::Udb3::Terms['uitdatabank-entry-api']]
    }
  }

  if $with_bulk_label_offer_worker {
    systemd::unit_file { 'udb3-bulk-label-offer-worker.service':
      content   => template('deployment/udb3/entry_api/udb3-bulk-label-offer-worker.service.erb')
    }

    service { 'udb3-bulk-label-offer-worker':
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      subscribe => [Package['uitdatabank-entry-api'], File['uitdatabank-entry-api-config'], File['uitdatabank-entry-api-admin-permissions'], File['uitdatabank-entry-api-client-permissions'], File['uitdatabank-entry-api-pubkey'], File['uitdatabank-entry-api-pubkey-auth0'], File['uitdatabank-entry-api-pubkey-keycloak'], Deployment::Udb3::Externalid['uitdatabank-entry-api'], Deployment::Udb3::Terms['uitdatabank-entry-api']]
    }
  }

  if $event_export_worker_count > 0 {
    systemd::unit_file { 'udb3-event-export-worker@.service':
      content => template('deployment/udb3/entry_api/udb3-event-export-worker@.service.erb')
    }

    Integer[1, $event_export_worker_count].each |$id| {
      service { "udb3-event-export-worker@${id}":
        ensure    => 'running',
        enable    => true,
        hasstatus => true,
        subscribe => [Package['uitdatabank-entry-api'], File['uitdatabank-entry-api-config'], File['uitdatabank-entry-api-admin-permissions'], File['uitdatabank-entry-api-client-permissions'], File['uitdatabank-entry-api-pubkey'], File['uitdatabank-entry-api-pubkey-auth0'], File['uitdatabank-entry-api-pubkey-keycloak'], Deployment::Udb3::Externalid['uitdatabank-entry-api'], Deployment::Udb3::Terms['uitdatabank-entry-api']]
      }
    }

    systemd::unit_file { 'udb3-event-export-workers.target':
      content => template('deployment/udb3/entry_api/udb3-event-export-workers.target.erb'),
      enable  => true,
      active  => true
    }
  }

  deployment::udb3::externalid { 'uitdatabank-entry-api':
    directory                  => $basedir,
    place_mapping_source       => $externalid_place_mapping_source,
    organizer_mapping_source   => $externalid_organizer_mapping_source,
    place_mapping_filename     => 'config.external_id_mapping_place.php',
    organizer_mapping_filename => 'config.external_id_mapping_organizer.php',
    require                    => Package['uitdatabank-entry-api'],
    notify                     => Class['apache::service'],
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
    notify                      => Class['apache::service'],
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
    postrotate    => '/bin/systemctl restart udb3-amqp-listener-uitpas udb3-bulk-label-offer-worker udb3-event-export-workers.target',
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

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::entry_api']
}
