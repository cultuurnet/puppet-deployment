class deployment::omd::mediadownloadmanager (
  $config_source,
  $project_prefix = 'omd',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  package { 'omd-media-download-manager':
    ensure => 'latest',
    notify => [ Class['apache::service'], Profiles::Deployment::Versions[$title]],
    noop   => $noop_deploy
  }

  file { 'omd-media-download-manager-log':
    ensure  => 'directory',
    path    => '/var/www/media-download-manager/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[omd-media-download-manager]',
    noop    => $noop_deploy
  }

  file { 'omd-media-download-manager-config':
    ensure  => 'file',
    path    => '/var/www/media-download-manager/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[omd-media-download-manager]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  logrotate::rule { 'omd-media-download-manager':
    path          => '/var/www/media-download-manager/log/*.log',
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
    require       => 'Package[omd-media-download-manager]',
    noop          => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::omd::mediadownloadmanager']
}
