class deployment::projectaanvraag (
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  if $update_facts {
    exec { 'update_facts':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::projectaanvraag']
}
