class deployment::widgetbeheer::angular (
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'widgetbeheer-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'widgetbeheer',
    packages     => 'widgetbeheer-angular-app',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
