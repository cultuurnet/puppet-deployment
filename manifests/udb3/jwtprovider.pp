class deployment::udb3::jwtprovider (
  $config_source,
  $privkey_source,
  $pubkey_source,
  $project_prefix = 'udb3',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  package { 'udb3-jwt':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-jwtprovider-config':
    ensure  => 'file',
    path    => '/var/www/udb-jwt-provider/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-log':
    ensure  => 'directory',
    path    => '/var/www/udb-jwt-provider/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-privkey':
    ensure  => 'file',
    path    => '/var/www/udb-jwt-provider/private.pem',
    source  => $privkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwtprovider-pubkey':
    ensure  => 'file',
    path    => '/var/www/udb-jwt-provider/public.pem',
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-jwt',
    noop_deploy  => $noop_deploy,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::jwtprovider']
}
