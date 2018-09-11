class deployment::omd::angular (
  $angular_app_config_source,
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'omd-angular-app':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'omd-angular-app-config':
    ensure => 'file',
    path   => '/var/www/omd-app/config.json',
    source => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[omd-angular-app]',
    noop    => $noop_deploy
  }

  file { 'omd-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
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

  if $update_facts {
    exec { 'update_facts omd':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[omd]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::omd::angular']
}