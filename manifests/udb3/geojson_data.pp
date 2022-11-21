class deployment::udb3::geojson_data (
  $version      = 'latest',
  $noop_deploy  = false,
  $puppetdb_url = lookup('data::puppet::puppetdb::url', Optional[String], 'first', undef)
) {

  realize Apt::Source['uitdatabank-geojson-data']

  package { 'uitdatabank-geojson-data':
    ensure  => $version,
    notify  => Profiles::Deployment::Versions[$title],
    require => Apt::Source['uitdatabank-geojson-data'],
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }
}
