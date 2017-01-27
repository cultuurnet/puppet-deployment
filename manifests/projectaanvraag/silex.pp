class deployment::projectaanvraag::silex (
  $silex_config_source,
  $angular_app_config_source,
  $angular_app_deploy_config_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'projectaanvraag-silex':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'projectaanvraag-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'projectaanvraag':
    ensure  => 'latest',
    require => [ 'Package[projectaanvraag-silex]', 'Package[projectaanvraag-angular-app]' ],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-silex-config':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[projectaanvraag-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-config':
    ensure => 'file',
    path   => '/var/www/projectaanvraag/config.json',
    source => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[projectaanvraag-angular-app]',
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/projectaanvraag',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[projectaanvraag-angular-app]', 'File[projectaanvraag-angular-app-config]', 'File[projectaanvraag-angular-app-deploy-config]'],
    refreshonly => true,
    notify      => 'Class[Supervisord::Service]',
    noop        => $noop_deploy
  }

  exec { 'silex-db-install':
    command   => 'bin/console orm:schema-tool:create',
    cwd       => '/var/www/projectaanvraag-api',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/projectaanvraag-api'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    subscribe => 'Package[projectaanvraag-silex]',
    noop      => $noop_deploy
  }

  exec { 'silex-db-migrate':
    command     => 'bin/console orm:schema-tool:update --force',
    cwd         => '/var/www/projectaanvraag-api',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/projectaanvraag-api'],
    subscribe   => 'Package[projectaanvraag-silex]',
    require     => 'Exec[silex-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts projectaanvraag':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[projectaanvraag]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::projectaanvraag::silex']
}
