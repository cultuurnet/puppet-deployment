class deployment::udb3::jwtprovider (
  $config_source,
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  $basedir = '/var/www/udb3-jwt-provider'

  realize Apt::Source['uitdatabank-jwt-provider']

  package { 'uitdatabank-jwt-provider':
    ensure  => 'latest',
    notify  => 'Class[Apache::Service]',
    require => Apt::Source['uitdatabank-jwt-provider'],
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-config':
    ensure  => 'file',
    path    => "${basedir}/config.yml",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitdatabank-jwt-provider]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[uitdatabank-jwt-provider]',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => 'uitdatabank',
    packages     => 'uitdatabank-jwt-provider]',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::jwtprovider']
}
