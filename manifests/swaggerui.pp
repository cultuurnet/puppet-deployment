class deployment::swaggerui (
  $config_source,
  $deploy_config_source,
  $noop_deploy = false,
) {

  contain deployment

  package { 'swagger-ui':
    ensure  => 'latest',
    noop    => $noop_deploy
  }

  file { 'swagger-ui-config':
    ensure => 'file',
    path   => '/var/www/swagger-ui/config.json',
    source => config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[swagger-ui]',
    noop    => $noop_deploy
  }

  file { 'swagger-ui-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/swagger-deploy-config',
    source => deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'swagger-deploy-config':
    command     => 'swagger-deploy-config /var/www/swagger-ui',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[swagger-ui]', 'File[swagger-ui-config]', 'File[swagger-ui-deploy-config]'],
    refreshonly => true,
    require     => Class['deployment'],
    noop        => $noop_deploy
  }
}
