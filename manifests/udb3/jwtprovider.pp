class deployment::udb3::jwtprovider (
  $config_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
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

  if $update_facts {
    exec { 'update_facts':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
