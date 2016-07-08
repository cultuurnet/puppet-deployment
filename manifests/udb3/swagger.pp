class deployment::udb3::swagger (
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-swagger':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts swagger':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-swagger]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
