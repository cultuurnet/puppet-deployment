class deployment::udb3::search (
  $config_source,
  $features_source,
  $migrate_data = true,
  $migrate_timeout = '300',
  $reindex_permanent_hour = '0',
  $reindex_permanent_minute = '0',
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

  file { 'udb3-search-features':
    ensure  => 'file',
    path    => '/var/www/udb-search/features.yml',
    source  => $features_source,
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

  if $migrate_data {
    exec { 'search-elasticsearch-migrate':
      command     => 'bin/app.php elasticsearch:migrate',
      cwd         => '/var/www/udb-search',
      path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-search'],
      subscribe   => 'File[udb3-search-config]',
      logoutput   => true,
      timeout     => $migrate_timeout,
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  cron { 'reindex_permanent':
    command    => '/var/www/udb-search/bin/app.php udb3-core:reindex-permanent',
    require    => 'Package[udb3-search]',
    user       => 'root',
    hour       => $reindex_permanent_hour,
    minute     => $reindex_permanent_minute
  }

  deployment::versions { $title:
    project      => 'udb3',
    packages     => [ 'udb3-search', 'udb3-geojson-data'],
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::search']
}
