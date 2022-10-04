class deployment::udb3::jwtprovider (
  $config_source,
  $project_prefix = 'udb3',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  $basedir = '/var/www/udb-jwt-provider'

  realize Apt::Source['cultuurnet-jwtprovider']

  package { 'udb3-jwt-provider':
    ensure  => 'latest',
    notify  => 'Class[Apache::Service]',
    require => Apt::Source['cultuurnet-jwtprovider'],
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-config':
    ensure  => 'file',
    path    => "${basedir}/config.yml",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt-provider]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-jwt-provider]',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-jwt-provider',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::jwtprovider']
}
