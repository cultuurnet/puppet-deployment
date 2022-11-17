class deployment::udb3::cdbxml (
  $config_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $db_name,
  $project_prefix = 'udb3',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  apt::source { 'cultuurnet-cdbxml':
    location => "http://apt.uitdatabank.be/cdbxml-${environment}",
    release => $facts['lsbdistcodename'],
    repos   => 'main',
    include => {
      'deb' => true,
      'src' => false
    },
    require => Class['profiles::apt::keys']
  }

  package { 'udb3-cdbxml':
    ensure  => 'latest',
    notify  => [ Class['apache::service'], Class['supervisord::service'], Profiles::Deployment::Versions[$title]],
    require => Apt::Source['cultuurnet-cdbxml'],
    noop    => $noop_deploy
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

  file { 'udb3-cdbxml-log':
    ensure  => 'directory',
    path    => '/var/www/udb-cdbxml/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
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
    require       => 'File[udb3-cdbxml-log]',
    noop          => $noop_deploy
  }

  exec { 'cdbxml_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/udb-cdbxml',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-cdbxml'],
    subscribe   => 'Package[udb3-cdbxml]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::cdbxml']
}
