class deployment::projectaanvraag::angular (
  $config_source,
  $version              = 'latest',
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy          = false,
  $puppetdb_url         = undef
) {

  contain deployment

  realize Apt::Source['projectaanvraag-frontend']

  package { 'projectaanvraag-frontend':
    ensure => $version,
    notify => Profiles::Deployment::Versions[$title],
    noop   => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-config':
    ensure => 'file',
    path   => '/var/www/projectaanvraag-frontend/config.json',
    source => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['projectaanvraag-frontend'],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/projectaanvraag-frontend',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[projectaanvraag-frontend]', 'File[projectaanvraag-angular-app-config]', 'File[projectaanvraag-angular-app-deploy-config]'],
    refreshonly => true,
    require     => Class['deployment'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }
}
