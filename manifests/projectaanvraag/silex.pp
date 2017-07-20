class deployment::projectaanvraag::silex (
  $silex_config_source,
  $silex_user_roles_source,
  $silex_integration_types_source,
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

  file { 'projectaanvraag-silex-user_roles':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/user_roles.yml',
    source  => $silex_user_roles_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[projectaanvraag-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-silex-integration_types':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/integration_types.yml',
    source  => $silex_integration_types_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[projectaanvraag-silex]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
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

  deployment::versions { $title:
    project      => 'projectaanvraag',
    packages     => 'projectaanvraag-silex',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::projectaanvraag::silex']
}