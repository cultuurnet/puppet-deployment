class deployment::udb3::search (
  $config_source,
  $features_source,
  $facet_mapping_facilities_source,
  $facet_mapping_themes_source,
  $facet_mapping_types_source,
  $search_package_version   = 'latest',
  $geojson_package_version  = 'latest',
  $migrate_data             = true,
  $project_prefix           = 'udb3',
  $migrate_timeout          = '300',
  $reindex_permanent_hour   = '0',
  $reindex_permanent_minute = '0',
  $region_mapping_source    = 'puppet:///modules/deployment/search/mapping_region.json',
  $noop_deploy              = false,
  $puppetdb_url             = undef
) {

  File {
    owner   => 'www-data',
    group   => 'www-data'
  }

  package { 'udb3-search':
    ensure => $search_package_version,
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'udb3-geojson-data':
    ensure => $geojson_package_version,
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

  deployment::udb3::terms { 'udb3-search':
    directory                   => '/var/www/udb-search',
    facilities_mapping_source   => $facet_mapping_facilities_source,
    themes_mapping_source       => $facet_mapping_themes_source,
    types_mapping_source        => $facet_mapping_types_source,
    facilities_mapping_filename => 'facet_mapping_facilities.yml',
    themes_mapping_filename     => 'facet_mapping_themes.yml',
    types_mapping_filename      => 'facet_mapping_types.yml',
    require                     => Package['udb3-search'],
    notify                      => [ Class['apache::service'], Class['supervisord::service']],
    noop                        => $noop_deploy
  }

  file { 'udb3-search-log':
    ensure  => 'directory',
    path    => '/var/www/udb-search/log',
    recurse => true,
    require => Package['udb3-search']
  }

  file { 'udb3-search-region-mapping':
    ensure  => 'file',
    path    => '/var/www/udb-search/src/ElasticSearch/Operations/json/mapping_region.json',
    source  => $region_mapping_source,
    require => Package['udb3-search'],
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
    require       => File['udb3-search-log'],
    noop          => $noop_deploy
  }

  if $migrate_data {
    exec { 'search-elasticsearch-migrate':
      command     => 'bin/app.php elasticsearch:migrate',
      cwd         => '/var/www/udb-search',
      path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-search'],
      subscribe   => [ File['udb3-search-config'], File['udb3-search-region-mapping'] ],
      require     => Deployment::Udb3::Terms['udb3-search'],
      logoutput   => true,
      timeout     => $migrate_timeout,
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  cron { 'reindex_permanent':
    command     => '/var/www/udb-search/bin/app.php udb3-core:reindex-permanent',
    environment => [ 'MAILTO=infra@publiq.be' ],
    require     => Package['udb3-search'],
    user        => 'root',
    hour        => $reindex_permanent_hour,
    minute      => $reindex_permanent_minute
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'udb3-search', 'udb3-geojson-data'],
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::search']
}
