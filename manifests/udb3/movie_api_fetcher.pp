class deployment::udb3::movie_api_fetcher (
  $silex_config_source,
  $db_name,
  $kinepolis_theaters_source = 'puppet:///modules/deployment/movie_api_fetcher/kinepolis_theaters.yml',
  $kinepolis_terms_source = 'puppet:///modules/deployment/movie_api_fetcher/kinepolis_terms.yml',
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-movie-api-fetcher':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-movie-api-fetcher-log':
    ensure  => 'directory',
    path    => '/var/www/movie-api-fetcher/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-movie-api-fetcher]',
    noop    => $noop_deploy
  }

  file { 'udb3-movie-api-fetcher-config':
    ensure  => 'file',
    path    => '/var/www/movie-api-fetcher/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-movie-api-fetcher]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-movie-api-fetcher-kinepolis-theaters':
    ensure  => 'file',
    path    => '/var/www/movie-api-fetcher/kinepolis_theaters.yml',
    source  => $kinepolis_theaters_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-movie-api-fetcher]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'udb3-movie-api-fetcher-kinepolis-terms':
    ensure  => 'file',
    path    => '/var/www/movie-api-fetcher/kinepolis_terms.yml',
    source  => $kinepolis_terms_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-movie-api-fetcher]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  logrotate::rule { 'udb3-movie-api-fetcher':
    path          => '/var/www/udb-movie-api-fetcher/log/*.log',
    rotate        => '10',
    rotate_every  => 'day',
    missingok     => true,
    compress      => true,
    delaycompress => true,
    ifempty       => false,
    create        => true,
    create_mode   => '0640',
    create_owner  => 'www-data',
    create_group  => 'www-data',
    sharedscripts => true,
    require       => 'Package[udb3-movie-api-fetcher]',
    noop          => $noop_deploy
  }

  exec { 'movie-api-fetcher-db-install':
    command   => 'bin/app.php install',
    cwd       => '/var/www/movie-api-fetcher',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/movie-api-fetcher'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\" and table_name not like \"doctrine_migration_versions\";')",
    subscribe => [ 'Package[udb3-movie-api-fetcher]', 'File[udb3-movie-api-fetcher-config]'],
    noop      => $noop_deploy
  }

  exec { 'movie-api-fetcher_db_migrate':
    command     => 'vendor/bin/doctrine-dbal --no-interaction migrations:migrate',
    cwd         => '/var/www/movie-api-fetcher',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/movie-api-fetcher'],
    onlyif      => 'test -d /var/www/movie-api-fetcher/src/Migrations',
    subscribe   => [ 'Package[udb3-movie-api-fetcher]', 'File[udb3-movie-api-fetcher-config]'],
    require     => 'Exec[movie-api-fetcher-db-install]',
    refreshonly => true,
    noop        => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'udb3',
    packages     => [ 'udb3-movie-api-fetcher'],
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::udb3::movie_api_fetcher']
}
