define deployment::udb3::externalid (
  $directory,
  $place_mapping_source,
  $organizer_mapping_source,
  $place_mapping_filename = 'external_id_mapping_place.yml',
  $organizer_mapping_filename = 'external_id_mapping_organizer.yml',
  $noop_deploy = false
) {

  file { "${directory}/${place_mapping_filename}":
    ensure => 'file',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => $place_mapping_source,
    noop   => $noop_deploy
  }

  file { "${directory}/${organizer_mapping_filename}":
    ensure => 'file',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => $organizer_mapping_source,
    noop   => $noop_deploy
  }
}
