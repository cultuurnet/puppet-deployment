define deployment::udb3::terms (
  $directory,
  $facilities_mapping_source,
  $themes_mapping_source,
  $types_mapping_source,
  $facilities_mapping_filename = 'term_mapping_facilities.yml',
  $themes_mapping_filename = 'term_mapping_themes.yml',
  $types_mapping_filename = 'term_mapping_types.yml',
  $noop_deploy = false
) {

  file { "${directory}/${facilities_mapping_filename}":
    ensure => 'file',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => $facilities_mapping_source,
    noop   => $noop_deploy
  }

  file { "${directory}/${themes_mapping_filename}":
    ensure => 'file',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => $themes_mapping_source,
    noop   => $noop_deploy
  }

  file { "${directory}/${types_mapping_filename}":
    ensure => 'file',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => $types_mapping_source,
    noop   => $noop_deploy
  }
}
