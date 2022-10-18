class deployment::udb3::search (
  $config_source,
  $features_source,
  $facet_mapping_facilities_source,
  $facet_mapping_themes_source,
  $facet_mapping_types_source,
  $version                  = 'latest',
  $migrate_data             = true,
  $migrate_timeout          = '300',
  $reindex_permanent_hour   = '0',
  $reindex_permanent_minute = '0',
  $region_mapping_source    = 'puppet:///modules/deployment/search/mapping_region.json',
  $noop_deploy              = false,
  $puppetdb_url             = undef
) {

  $basedir = '/var/www/udb3-search-service'

  File {
    owner   => 'www-data',
    group   => 'www-data'
  }

  realize Apt::Source['uitdatabank-search-api']

  include deployment::udb3::geojson_data

  package { 'uitdatabank-search-api':
    ensure  => $search_package_version,
    notify  => [Class['Apache::Service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    require => Apt::Source['uitdatabank-search-api'],
    noop    => $noop_deploy
  }

  file { 'udb3-search-config':
    ensure  => 'file',
    path    => "${basedir}/config.yml",
    source  => $config_source,
    require => Package['uitdatabank-search-api'],
    notify  => [Class['Apache::Service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop    => $noop_deploy
  }

  file { 'udb3-search-features':
    ensure  => 'file',
    path    => "${basedir}/features.yml",
    source  => $features_source,
    require => Package['uitdatabank-search-api'],
    notify  => [Class['Apache::Service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop    => $noop_deploy
  }

  # When running in noop_deploy the source of this file will not exist, and
  # applying the resource, even with noop => true will cause an error
  file { 'udb3-search-facet-mapping-regions':
    ensure  => 'file',
    path    => "${basedir}/facet_mapping_regions.yml",
    source  => '/var/www/geojson-data/output/facet_mapping_regions.yml',
    require => [Package['uitdatabank-search-api'], Class['deployment::udb3::geojson_data']],
    notify  => [Class['Apache::Service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop    => $noop_deploy
  }

  # When running in noop_deploy the source of this file will not exist, and
  # applying the resource, even with noop => true will cause an error
  file { 'udb3-search-autocomplete-json':
    ensure  => 'file',
    path    => "${basedir}/web/autocomplete.json",
    source  => '/var/www/geojson-data/output/autocomplete.json',
    require => [Package['uitdatabank-search-api'], Class['deployment::udb3::geojson_data']],
    notify  => [Class['Apache::Service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop    => $noop_deploy
  }

  deployment::udb3::terms { 'udb3-search':
    directory                   => $basedir,
    facilities_mapping_source   => $facet_mapping_facilities_source,
    themes_mapping_source       => $facet_mapping_themes_source,
    types_mapping_source        => $facet_mapping_types_source,
    facilities_mapping_filename => 'facet_mapping_facilities.yml',
    themes_mapping_filename     => 'facet_mapping_themes.yml',
    types_mapping_filename      => 'facet_mapping_types.yml',
    require                     => Package['uitdatabank-search-api'],
    notify                      => [Class['apache::service'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop                        => $noop_deploy
  }

  file { 'udb3-search-log':
    ensure  => 'directory',
    path    => "${basedir}/log",
    recurse => true,
    require => Package['uitdatabank-search-api']
  }

  file { 'udb3-search-region-mapping':
    ensure  => 'file',
    path    => "${basedir}/src/ElasticSearch/Operations/json/mapping_region.json",
    source  => $region_mapping_source,
    require => Package['uitdatabank-search-api'],
    noop    => $noop_deploy
  }

  service { 'udb3-consume-api':
    ensure    => 'running',
    enable    => true,
    hasstatus => true
  }

  service { 'udb3-consume-cli':
    ensure    => 'running',
    enable    => true,
    hasstatus => true
  }

  service { 'udb3-consume-related':
    ensure    => 'running',
    enable    => true,
    hasstatus => true
  }

  logrotate::rule { 'udb3-search':
    path          => "${basedir}/log/*.log",
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
    postrotate    => '/bin/systemctl restart udb3-consume-*',
    require       => [ File['udb3-search-log'], Service['udb3-consume-api'], Service['udb3-consume-cli'], Service['udb3-consume-related']],
    noop          => $noop_deploy
  }

  if $migrate_data {
    exec { 'search-elasticsearch-migrate':
      command     => 'bin/app.php elasticsearch:migrate',
      cwd         => $basedir,
      path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
      subscribe   => [ File['udb3-search-config'], File['udb3-search-region-mapping'] ],
      require     => Deployment::Udb3::Terms['udb3-search'],
      logoutput   => true,
      timeout     => $migrate_timeout,
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  cron { 'reindex_permanent':
    command     => "${basedir}/bin/app.php udb3-core:reindex-permanent",
    environment => ['MAILTO=infra@publiq.be'],
    require     => Package['uitdatabank-search-api'],
    user        => 'root',
    hour        => $reindex_permanent_hour,
    minute      => $reindex_permanent_minute
  }

  profiles::deployment::versions { $title:
    project      => 'uitdatabank',
    packages     => 'uitdatabank-search-api',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::search']
}
