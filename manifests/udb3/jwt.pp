class deployment::udb3::jwt (
  $config_source,
  $privkey_source,
  $pubkey_source,
  $project_prefix = 'udb3',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  $basedir = '/var/www/udb-jwt'

  package { 'udb3-jwt':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-jwt-config':
    ensure  => 'file',
    path    => "${basedir}/config.yml",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-privkey':
    ensure  => 'file',
    path    => "${basedir}/private.pem",
    source  => $privkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-pubkey':
    ensure  => 'file',
    path    => "${basedir}/public.pem",
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-jwt]',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'udb3-jwt',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::jwt']
}
