class deployment::udb3::uitpas (
  $config_source,
  $pubkey_source,
  $externalid_place_mapping_source,
  $externalid_organizer_mapping_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-uitpas':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  file { 'udb3-uitpas-config':
    ensure  => 'file',
    path    => '/var/www/udb-uitpas/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-uitpas]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'udb3-uitpas-log':
    ensure  => 'directory',
    path    => '/var/www/udb-uitpas/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[udb3-uitpas]',
    noop    => $noop_deploy
  }

  file { 'udb3-uitpas-pubkey':
    ensure  => 'file',
    path    => '/var/www/udb-uitpas/public.pem',
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-uitpas]',
    noop    => $noop_deploy
  }

  deployment::udb3::externalid { 'udb3-uitpas':
    directory                => '/var/www/udb-uitpas',
    place_mapping_source     => $externalid_place_mapping_source,
    organizer_mapping_source => $externalid_organizer_mapping_source,
    require                  => 'Package[udb3-uitpas]',
    notify                   => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop_deploy              => $noop_deploy
  }

  logrotate::rule { 'udb3-uitpas':
    path          => '/var/www/udb-uitpas/log/*.log',
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
    postrotate    => '/usr/bin/supervisorctl restart udb3-uitpas-service',
    require       => 'File[udb3-uitpas-log]',
    noop          => $noop_deploy
  }

  exec { 'uitpas-db-install':
    command   => 'bin/app.php install',
    cwd       => '/var/www/udb-uitpas',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-uitpas'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    subscribe => [ 'Package[udb3-uitpas]', 'File[udb3-uitpas-config]'],
    noop      => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 uitpas':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-uitpas]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::uitpas']
}
