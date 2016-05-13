class deployment::udb3::cdbxml (
  $config_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-cdbxml':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-cdbxml-config':
    ensure  => 'file',
    path    => '/var/www/udb-cdbxml/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-cdbxml]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-cdbxml]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}