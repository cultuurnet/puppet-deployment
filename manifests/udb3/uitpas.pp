class deployment::udb3::uitpas (
  $config_source,
  $pubkey_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $project_prefix = 'udb3',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  package { 'udb3-uitpas':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  file { 'udb3-uitpas-config':
    ensure  => 'file',
    path    => '/var/www/udb-uitpas/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-uitpas]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-uitpas-log':
    ensure  => 'directory',
    path    => '/var/www/udb-uitpas/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-uitpas]',
    noop    => $noop_deploy
  }

  file { 'udb3-uitpas-pubkey':
    ensure  => 'file',
    path    => '/var/www/udb-uitpas/public.pem',
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-uitpas]',
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'udb3-uitpas':
    directory                => '/var/www/udb-uitpas',
    place_mapping_source     => $externalid_place_mapping_source,
    organizer_mapping_source => $externalid_organizer_mapping_source,
    require                  => 'Package[udb3-uitpas]',
    notify                   => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop_deploy              => $noop_deploy
  }

  logrotate::rule { 'udb3-uitpas':
    path          => '/var/www/udb-uitpas/log/*.log',
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-uitpas-service',
    require       => 'File[udb3-uitpas-log]',
    noop          => $noop_deploy
  }

  deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-uitpas',
    noop_deploy  => $noop_deploy,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::uitpas']
}
