class deployment::omd (
  $omd_drupal_settings_source,
  $omd_drupal_services_source,
  $omd_drupal_admin_account_pass,
  $omd_drupal_db_url,
  $omd_drupal_uri,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'omd-drupal':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'omd':
    ensure  => 'latest',
    require => [ 'Package[omd-drupal]', 'Package[omd-websockets]'],
    noop    => $noop_deploy
  }

  file { 'omd-drupal-settings':
    path    => '/var/www/omd-drupal/sites/default/settings.local.php',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $omd_drupal_settings_source,
    require => 'Package[omd-drupal]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'omd-drupal-services':
    path    => '/var/www/omd-drupal/sites/default/services.yml',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $omd_drupal_services_source,
    require => 'Package[omd-drupal]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  exec { 'omd-site-install':
    command     => "/usr/bin/drush -r /var/www/omd-drupal site-install -y herita --account-pass=${omd_drupal_admin_account_pass} --db-url=${omd_drupal_db_url} --uri=${omd_drupal_uri}",
    path        => [ '/usr/local/bin', '/usr/bin'],
    onlyif      => '/usr/bin/test -z `/usr/bin/drush -r /var/www/omd-drupal core-status --format=list install-profile`',
    refreshonly => true,
    subscribe   => 'Package[omd-drupal]',
    require     => [ 'File[omd-drupal-settings]', 'File[omd-drupal-services]'],
    noop        => $noop_deploy
  }

  file { '/var/www/omd-drupal/sites/default/settings.php':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Exec[omd-site-install]',
    noop        => $noop_deploy
  }

  file { '/var/www/omd-drupal/sites/default/files':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Exec[omd-site-install]',
    noop        => $noop_deploy
  }

  exec { 'culturefeed-search-import-cities':
    command     => '/usr/bin/drush -r /var/www/omd-drupal culturefeed-search-import-cities',
    path        => [ '/usr/local/bin', '/usr/bin'],
    subscribe   => 'Exec[omd-site-install]',
    refreshonly => true,
    require     => [ 'Package[omd-drupal]', 'File[omd-drupal-settings]', 'File[omd-drupal-services]'],
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[omd]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
