class deployment::balie (
  $silex_config_source,
  $angular_app_config_source,
  $silex_package_version = 'latest',
  $angular_package_version = 'latest',
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $project_prefix = 'balie',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  realize Apt::Source['uitpas-balie-frontend']
  realize Apt::Source['uitpas-balie-api']

  package { 'uitpas-balie-api':
    ensure  => $silex_package_version,
    notify  => 'Class[Apache::Service]',
    require => Apt::Source['uitpas-balie-api'],
    noop    => $noop_deploy
  }

  package { 'uitpas-balie-frontend':
    ensure  => $angular_package_version,
    require => [ 'Package[uitpas-balie-api]', Apt::Source['uitpas-balie-api'] ],
    noop    => $noop_deploy
  }

  file { 'balie-silex-log':
    path    => '/var/www/uitpas-balie-api/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[uitpas-balie-api]',
    noop    => $noop_deploy
  }

  file { 'balie-silex-config':
    ensure  => 'file',
    path    => '/var/www/uitpas-balie-api/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitpas-balie-api]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-config':
    ensure  => 'file',
    path    => '/var/www/uitpas-balie-api/web/app/config.json',
    source  => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitpas-balie-frontend]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/uitpas-balie-api/web/app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[uitpas-balie-frontend]', 'File[balie-angular-app-config]', 'File[balie-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'uitpas-balie-frontend', 'uitpas-balie-api'],
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::balie']
}
