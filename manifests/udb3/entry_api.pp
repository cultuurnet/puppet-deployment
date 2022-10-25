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
  $project_prefix              = 'udb3',
  $event_conclude_ensure       = 'present',
  $event_conclude_hour         = '0',
  $event_conclude_minute       = '0',
  $noop_deploy                 = false,
  $puppetdb_url                = undef,
  $excluded_labels_source      = undef
) {

  realize Apt::Source['cultuurnet-udb3']

  $basedir = '/var/www/udb-silex'

  package { 'udb3-silex':
    ensure  => 'latest',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => Package['udb3-silex'],
    noop    => $noop_deploy
  }

  file { 'udb3-uploads':
    ensure  => 'directory',
    path    => "${basedir}/web/uploads",
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    noop    => $noop_deploy
  }

  file { 'udb3-downloads':
    ensure  => 'directory',
    path    => "${basedir}/web/downloads",
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-config':
    ensure  => 'file',
    path    => "${basedir}/config.php",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop    => $noop_deploy
  }

  if $excluded_labels_source {
    file { 'udb3-silex-excluded-labels':
      ensure  => 'file',
      path    => "${basedir}/config.excluded_labels.php",
      source  => $excluded_labels_source,
      owner   => 'www-data',
      group   => 'www-data',
      require => Package['udb3-silex'],
      notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
      noop    => $noop_deploy
    }
  }

  file { 'udb3-silex-permissions':
    ensure  => 'file',
    path    => "{basedir}/config.allow_all.php",
    source  => $permissions_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    notify  => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-pubkey':
    ensure  => 'file',
    path    => "${basedir}/public.pem",
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    noop    => $noop_deploy
  }

  file { 'udb3-silex-pubkey-auth0':
    ensure  => 'file',
    path    => "${basedir}/public-auth0.pem",
    source  => $pubkey_auth0_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['udb3-silex'],
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'udb3-silex':
    directory                  => $basedir,
    place_mapping_source       => $externalid_place_mapping_source,
    organizer_mapping_source   => $externalid_organizer_mapping_source,
    place_mapping_filename     => 'config.external_id_mapping_place.php',
    organizer_mapping_filename => 'config.external_id_mapping_organizer.php',
    require                    => Package['udb3-silex'],
    notify                     => [ Class['Apache::Service'], Class['Supervisord::Service']],
    noop_deploy                => $noop_deploy
  }

  deployment::udb3::terms { 'udb3-silex':
    directory                   => $basedir,
    facilities_mapping_source   => $term_mapping_facilities_source,
    themes_mapping_source       => $term_mapping_themes_source,
    types_mapping_source        => $term_mapping_types_source,
    facilities_mapping_filename => 'config.term_mapping_facilities.php',
    themes_mapping_filename     => 'config.term_mapping_themes.php',
    types_mapping_filename      => 'config.term_mapping_types.php',
    require                     => Package['udb3-silex'],
    notify                      => [ Class['apache::service'], Class['supervisord::service']],
    noop_deploy                 => $noop_deploy
  }

  logrotate::rule { 'udb3-silex':
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
    require       => Package['udb3-silex'],
    noop          => $noop_deploy
  }

  exec { 'silex_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
    subscribe   => Package['udb3-silex'],
    refreshonly => true,
    noop        => $noop_deploy
  }

  cron { 'event_conclude':
    ensure  => $event_conclude_ensure,
    command => "${basedir}/bin/udb3.php event:conclude",
    require => Package['udb3-silex'],
    user    => 'root',
    hour    => $event_conclude_hour,
    minute  => $event_conclude_minute
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-silex',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::entry_api']
}
