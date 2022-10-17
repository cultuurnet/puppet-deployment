class deployment::udb3::geojson_data (
  $version      = 'latest',
  $noop_deploy  = false,
  $puppetdb_url = undef
) {

  realize Apt::Source['uitdatabank-geojson-data']

  package { 'uitdatabank-geojson-data':
    ensure  => $version,
    require => Apt::Source['uitdatabank-geojson-data'],
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => 'uitdatabank',
    packages     => 'uitdatabank-geojson-data',
    puppetdb_url => $puppetdb_url
  }
}
