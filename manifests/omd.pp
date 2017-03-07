class deployment::omd (
  $angular_app_config_source,
  $angular_app_deploy_config_source,
  $drupal_settings_source,
  $drupal_services_source,
  $drupal_admin_account_pass,
  $drupal_db_url,
  $drupal_uri,
  $pubkey_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'omd-angular-app':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  file { 'omd-angular-app-config':
    ensure => 'file',
    path   => '/var/www/omd-app/config.json',
    source => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[omd-angular-app]',
    noop    => $noop_deploy
  }

  file { 'omd-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/omd-app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[omd-angular-app]', 'File[omd-angular-app-config]', 'File[omd-angular-app-deploy-config]'],
    refreshonly => true,
    notify      => 'Class[Supervisord::Service]',
    noop        => $noop_deploy
  }

  package { 'omd-drupal':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'omd':
    ensure  => 'latest',
    require => [ 'Package[omd-angular-app], Package[omd-drupal]', 'Package[omd-websockets]'],
    noop    => $noop_deploy
  }

  file { 'omd-drupal-settings':
    path    => '/var/www/omd-drupal/sites/default/settings.local.php',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $drupal_settings_source,
    require => 'Package[omd-drupal]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  file { 'omd-drupal-services':
    path    => '/var/www/omd-drupal/sites/default/services.yml',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $drupal_services_source,
    require => 'Package[omd-drupal]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
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

  exec { 'omd-site-install':
    command     => "/usr/bin/drush -r /var/www/omd-drupal site-install -y herita --account-pass=${drupal_admin_account_pass} --db-url=${drupal_db_url} --uri=${drupal_uri}",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
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

  if $update_facts {
    exec { 'update_facts omd':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[omd]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::omd']
}
