class deployment::udb3::search (
  $config_source,
  $migrate_timeout = '300',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-search':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'udb3-geojson-data':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'udb3-search-config':
    ensure  => 'file',
    path    => '/var/www/udb-search/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-log':
    ensure  => 'directory',
    path    => '/var/www/udb-search/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-search]',
    noop    => $noop_deploy
  }

  logrotate::rule { 'udb3-search':
    path          => '/var/www/udb-search/log/*.log',
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-search-service',
    require       => 'File[udb3-search-log]',
    noop          => $noop_deploy
  }

  exec { 'search-elasticsearch-migrate':
    command     => 'bin/app.php elasticsearch:migrate',
    cwd         => '/var/www/udb-search',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-search'],
    subscribe   => 'File[udb3-search-config]',
    timeout     => $migrate_timeout,
    refreshonly => true,
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 search':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => [ 'Package[udb3-search]', 'Package[udb3-geojson-data]' ],
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::search']
}
