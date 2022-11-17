class deployment::groepspas (
  $angular_app_config_source,
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  $basedir = '/var/www/uitpas-groepspas-frontend'

  realize Apt::Source['uitpas-groepspas-frontend']

  package { 'uitpas-groepspas-frontend':
    ensure  => 'latest',
    notify  => Profiles::Deployment::Versions[$title],
    require => Apt::Source['uitpas-groepspas-frontend'],
    noop    => $noop_deploy
  }

  file { 'uitpas-groepspas-frontend-config':
    ensure  => 'file',
    path    => "${basedir}/config.json",
    source  => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitpas-groepspas-frontend]',
    noop    => $noop_deploy
  }

  file { 'uitpas-groepspas-frontend-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular2-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular2-deploy-config':
    command     => "angular2-deploy-config ${basedir}",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[uitpas-groepspas-frontend]', 'File[uitpas-groepspas-frontend-config]', 'File[uitpas-groepspas-frontend-deploy-config]'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }
}
