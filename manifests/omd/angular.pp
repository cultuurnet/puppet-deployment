class deployment::omd::angular (
  $config_source,
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $project_prefix = 'omd',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  contain deployment

  package { 'omd-angular-app':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'omd-angular-app-config':
    ensure => 'file',
    path   => '/var/www/omd-app/config.json',
    source => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[omd-angular-app]',
    noop    => $noop_deploy
  }

  file { 'omd-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/omd-app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[omd-angular-app]', 'File[omd-angular-app-config]', 'File[omd-angular-app-deploy-config]'],
    refreshonly => true,
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'omd-angular-app'],
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::omd::angular']
}
