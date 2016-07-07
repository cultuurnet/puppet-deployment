class deployment::swaggerui (
  $swagger_ui_config_source,
  $swagger_ui_deploy_config_source,
  $noop_deploy = false,
) {

  package { 'swagger-ui':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  file { 'swagger-ui-config':
    ensure => 'file',
    path   => '/var/www/swagger-ui/config.json',
    source => $swagger_ui_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[swagger-ui]',
    noop    => $noop_deploy
  }

  file { 'swagger-ui-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/swagger-deploy-config',
    source => $swagger_ui_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'swagger-deploy-config':
    command     => 'swagger-deploy-config /var/www/swagger-ui',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'File[swagger-ui-config]', 'File[swagger-ui-deploy-config]'],
    refreshonly => true,
    noop        => $noop_deploy
  }
}
