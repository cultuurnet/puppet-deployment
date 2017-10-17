class deployment::udb3::search (
  $config_source,
  $features_source,
  $facet_mapping_facilities_source,
  $facet_mapping_themes_source,
  $facet_mapping_types_source,
  $migrate_data = true,
  $migrate_timeout = '300',
  $reindex_permanent_hour = '0',
  $reindex_permanent_minute = '0',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  File {
    owner   => 'www-data',
    group   => 'www-data'
  }

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
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-features':
    ensure  => 'file',
    path    => '/var/www/udb-search/features.yml',
    source  => $features_source,
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-facet-mapping-facilities':
    ensure  => 'file',
    path    => '/var/www/udb-search/facet_mapping_facilities.yml',
    source  => $facet_mapping_facilities_source,
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  # When running in noop_deploy the source of this file will not exist, and
  # applying the resource, even with noop => true will cause an error
  file { 'udb3-search-facet-mapping-regions':
    ensure  => 'file',
    path    => '/var/www/udb-search/facet_mapping_regions.yml',
    source  => '/var/www/geojson-data/output/facet_mapping_regions.yml',
    require => [ 'Package[udb3-search]', 'Package[udb3-geojson-data]'],
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  # When running in noop_deploy the source of this file will not exist, and
  # applying the resource, even with noop => true will cause an error
  file { 'udb3-search-autocomplete-json':
    ensure  => 'file',
    path    => '/var/www/udb-search/web/autocomplete.json',
    source  => '/var/www/geojson-data/output/autocomplete.json',
    require => [ 'Package[udb3-search]', 'Package[udb3-geojson-data]'],
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-facet-mapping-themes':
    ensure  => 'file',
    path    => '/var/www/udb-search/facet_mapping_themes.yml',
    source  => $facet_mapping_themes_source,
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-facet-mapping-types':
    ensure  => 'file',
    path    => '/var/www/udb-search/facet_mapping_types.yml',
    source  => $facet_mapping_types_source,
    require => 'Package[udb3-search]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-log':
    ensure  => 'directory',
    path    => '/var/www/udb-search/log',
    recurse => true,
    require => 'Package[udb3-search]'
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
