class deployment::projectaanvraag::angular (
  $angular_app_config_source,
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'projectaanvraag-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-config':
    ensure => 'file',
    path   => '/var/www/projectaanvraag/config.json',
    source => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[projectaanvraag-angular-app]',
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/projectaanvraag',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[projectaanvraag-angular-app]', 'File[projectaanvraag-angular-app-config]', 'File[projectaanvraag-angular-app-deploy-config]'],
    refreshonly => true,
    noop        => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'projectaanvraag',
    packages     => 'projectaanvraag-angular',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
