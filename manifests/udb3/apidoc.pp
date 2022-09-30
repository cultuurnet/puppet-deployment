class deployment::udb3::apidoc (
  $project_prefix = 'udb3',
  $noop_deploy    = false,
  $puppetdb_url   = undef
) {

  realize Apt::Source['cultuurnet-udb3']

  package { 'udb3-swagger':
    ensure  => 'latest',
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop_deploy
  }

  package { 'udb3-schema':
    ensure  => 'latest',
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'udb3-swagger', 'udb3-schema'],
    puppetdb_url => $puppetdb_url
  }
}
