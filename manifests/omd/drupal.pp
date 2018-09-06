class deployment::omd::drupal (
  $drupal_settings_source,
  $drupal_db_source,
  $drupal_fs_source,
  $pubkey_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  contain deployment

  package { 'omd-drupal':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  package { 'omd-fs-data':
    ensure  => 'latest',
    notify  => 'Class[Apache::Service]',
    require => 'Package[omd-drupal]',
    noop    => $noop_deploy
  }

  package { 'omd-db-data':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'omd-drupal-settings':
    path    => '/var/www/omd-drupal/sites/default/settings.php',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $drupal_settings_source,
    require => 'Package[omd-drupal]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'omd-drupal-pubkey':
    ensure  => 'file',
    path    => '/var/www/omd-drupal/sites/default/public.pem',
    source  => $pubkey_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[omd-drupal]',
    noop    => $noop_deploy
  }

  exec { 'omd-db-install':
    command     => "drush -r /var/www/omd-drupal sql-query --file=${drupal_db_source}",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    onlyif      => 'test 0 -eq $(drush -r /var/www/omd-drupal sql-query "show tables" | sed -e "/^$/d" | wc -l)',
    refreshonly => true,
    subscribe   => [ 'Package[omd-drupal]', 'Package[omd-db-data]', 'File[omd-drupal-settings]'],
    noop        => $noop_deploy
  }

  exec { 'drush updatedb':
    command     => "drush -r /var/www/omd-drupal updatedb -y",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[omd-drupal]', 'File[omd-drupal-settings]'],
    require     => 'Exec[omd-db-install]',
    noop        => $noop_deploy
  }

  exec { 'drush config-split-import':
    command     => "drush -r /var/www/omd-drupal config-split-import -y",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[omd-drupal]', 'File[omd-drupal-settings]'],
    require     => [ 'Package[omd-fs-data]', 'Exec[omd-db-install]', 'Exec[drush updatedb]'],
    noop        => $noop_deploy
  }

  exec { 'drush cache-rebuild':
    command     => "drush -r /var/www/omd-drupal cache-rebuild",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[omd-drupal]', 'File[omd-drupal-settings]', 'Package[omd-fs-data]'],
    require     => 'Exec[drush config-split-import]',
    noop        => $noop_deploy
  }

  file { '/var/www/omd-drupal/sites/default/files':
    ensure  => 'directory',
    source  => $drupal_fs_source,
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[omd-fs-data]',
    noop    => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts omd':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[omd]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::omd::drupal']
}
