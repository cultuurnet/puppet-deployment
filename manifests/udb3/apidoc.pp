class deployment::udb3::apidoc (
  $project_prefix = 'udb3',
  $noop_deploy    = false,
  $puppetdb_url   = undef
) {

  package { 'udb3-swagger':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  package { 'udb3-schema':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'udb3-swagger', 'udb3-schema'],
    noop_deploy  => $noop_deploy,
    puppetdb_url => $puppetdb_url
  }
}
