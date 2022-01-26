class deployment::groepspas (
  $angular_app_config_source,
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $project_prefix = 'groepspas',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  realize Apt::Source['cultuurnet-groepspas']

  package { 'groepspas-angular-app':
    ensure  => 'latest',
    require => Apt::Source['cultuurnet-groepspas'],
    noop    => $noop_deploy
  }

  file { 'groepspas-angular-app-config':
    ensure  => 'file',
    path    => '/var/www/groepspas/config.json',
    source  => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[groepspas-angular-app]',
    noop    => $noop_deploy
  }

  file { 'groepspas-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular2-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular2-deploy-config':
    command     => 'angular2-deploy-config /var/www/groepspas',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[groepspas-angular-app]', 'File[groepspas-angular-app-config]', 'File[groepspas-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => 'groepspas-angular-app',
    puppetdb_url => $puppetdb_url
  }
}
