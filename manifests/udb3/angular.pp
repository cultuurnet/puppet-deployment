class deployment::udb3::angular (
  $config_source,
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  contain deployment

  package { 'udb3-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'udb3-angular-app-config':
    ensure => 'file',
    path   => '/var/www/udb-app/config.json',
    source => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-angular-app]',
    noop    => $noop_deploy
  }

  file { 'udb3-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/udb-app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[udb3-angular-app]', 'File[udb3-angular-app-config]', 'File[udb3-angular-app-deploy-config]'],
    refreshonly => true,
    require     => Class['deployment'],
    noop        => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'udb3',
    packages     => 'udb3-angular-app',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
