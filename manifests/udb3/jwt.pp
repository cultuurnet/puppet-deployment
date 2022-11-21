class deployment::udb3::jwt (
  $config_source,
  $privkey_source,
  $pubkey_source,
  $noop_deploy = false,
  $puppetdb_url = lookup('data::puppet::puppetdb::url', Optional[String], 'first', undef)
) {

  $basedir = '/var/www/udb3-jwt-provider-uitidv1'

  realize Apt::Source['uitdatabank-jwt-provider-uitidv1']

  package { 'uitdatabank-jwt-provider-uitidv1':
    ensure => 'latest',
    notify => [Class['apache::service'], Profiles::Deployment::Versions[$title]],
    noop   => $noop_deploy
  }

  file { 'udb3-jwt-config':
    ensure  => 'file',
    path    => "${basedir}/config.yml",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitdatabank-jwt-provider-uitidv1]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[uitdatabank-jwt-provider-uitidv1]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-privkey':
    ensure  => 'file',
    path    => "${basedir}/private.pem",
    source  => $privkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitdatabank-jwt-provider-uitidv1]',
    noop    => $noop_deploy
  }

  file { 'udb3-jwt-pubkey':
    ensure  => 'file',
    path    => "${basedir}/public.pem",
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitdatabank-jwt-provider-uitidv1]',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::jwt']
}
