class deployment::udb3::apidoc (
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-swagger':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  package { 'udb3-schema':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'udb3',
    packages     => [ 'udb3-swagger', 'udb3-schema'],
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
