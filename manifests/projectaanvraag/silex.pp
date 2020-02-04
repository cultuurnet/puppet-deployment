class deployment::projectaanvraag::silex (
  $config_source,
  $user_roles_source,
  $integration_types_source,
  $db_name,
  $package_version = 'latest',
  $noop_deploy     = false,
  $puppetdb_url    = undef
) {

  contain deployment

  package { 'projectaanvraag-silex':
    ensure => $package_version,
    notify => [ Class['apache::service'], Class['supervisord::service'] ],
    noop   => $noop_deploy
  }

  file { 'projectaanvraag-silex-config':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['projectaanvraag-silex'],
    notify  => [ Class['apache::service'], Class['supervisord::service'] ],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-silex-user_roles':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/user_roles.yml',
    source  => $user_roles_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['projectaanvraag-silex'],
    notify  => [ Class['apache::service'], Class['supervisord::service'] ],
    noop    => $noop_deploy
  }

  file { 'projectaanvraag-silex-integration_types':
    ensure  => 'file',
    path    => '/var/www/projectaanvraag-api/integration_types.yml',
    source  => $integration_types_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['projectaanvraag-silex'],
    notify  => [ Class['apache::service'], Class['supervisord::service'] ],
    noop    => $noop_deploy
  }

  exec { 'projectaanvraag-cache-clear':
    command     => 'bin/console projectaanvraag:cache-clear',
    cwd         => '/var/www/projectaanvraag-api',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/projectaanvraag-api'],
    logoutput   => true,
    refreshonly => true,
    subscribe   => [ File['projectaanvraag-silex-config'], Package['projectaanvraag-silex'] ],
    noop        => $noop_deploy
  }

  exec { 'silex-db-install':
    command   => 'bin/console orm:schema-tool:create',
    cwd       => '/var/www/projectaanvraag-api',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/projectaanvraag-api'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    subscribe => Package['projectaanvraag-silex'],
    noop      => $noop_deploy
  }

  exec { 'silex-db-migrate':
    command     => 'bin/console orm:schema-tool:update --force',
    cwd         => '/var/www/projectaanvraag-api',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/projectaanvraag-api'],
    subscribe   => Package['projectaanvraag-silex'],
    require     => Exec['silex-db-install'],
    refreshonly => true,
    noop        => $noop_deploy
  }

  file { 'projectaanvraag-cache-directory':
    ensure  => 'directory',
    path    => '/var/www/projectaanvraag-api/cache',
    owner   => 'www-data',
    group   => 'www-data',
    require => [ Package['projectaanvraag-silex'], Exec['projectaanvraag-cache-clear'], Exec['silex-db-install'], Exec['silex-db-migrate']],
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => 'projectaanvraag',
    packages     => 'projectaanvraag-silex',
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::projectaanvraag::silex']
}
