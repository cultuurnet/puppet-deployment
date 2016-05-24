class deployment::balie (
  $balie_silex_config_source,
  $balie_angular_app_config_source,
  $balie_swagger_ui_config_source,
  $balie_angular_app_deploy_config_source,
  $balie_swagger_ui_deploy_config_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'balie-silex':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  package { 'balie-angular-app':
    ensure  => 'latest',
    require => 'Package[balie-silex]',
    noop    => $noop_deploy
  }

  package { 'balie-swagger-ui':
    ensure  => 'latest',
    require => 'Package[balie-silex]',
    noop    => $noop_deploy
  }

  package { 'balie':
    ensure  => 'latest',
    require => [ 'Package[balie-silex]', 'Package[balie-angular-app]', 'Package[balie-swagger-ui]'],
    noop    => $noop_deploy
  }

  file { 'balie-silex-config':
    ensure  => 'file',
    path    => '/var/www/balie/config.yml',
    source  => $balie_silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-silex]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-config':
    ensure  => 'file',
    path    => '/var/www/balie/web/app/config.json',
    source  => $balie_angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-angular-app]',
    noop    => $noop_deploy
  }

  file { 'balie-swagger-ui-config':
    ensure  => 'file',
    path    => '/var/www/balie/web/swagger/config.json',
    source  => $balie_swagger_ui_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-swagger-ui]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $balie_angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  file { 'balie-swagger-ui-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/swagger-deploy-config',
    source => $balie_swagger_ui_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/balie/web/app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[balie-angular-app]', 'File[balie-angular-app-config]', 'File[balie-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  exec { 'swagger-deploy-config':
    command     => 'swagger-deploy-config /var/www/balie/web/swagger',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[balie-angular-app]', 'File[balie-angular-app-config]', 'File[balie-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[balie]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
