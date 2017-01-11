class deployment::udb3::drupal (
  $drupal_settings_source,
  $drupal_admin_account_pass,
  $drupal_db_url,
  $drupal_uri,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-drupal':
    ensure => 'present',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  package { 'udb3-alternative':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $noop_deploy
  }

  file { 'udb3-drupal-settings':
    path    => '/var/www/udb-drupal/sites/default/settings.local.php',
    source  => $drupal_settings_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-drupal]',
    notify  => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop    => $noop_deploy
  }

  exec { 'udb3-site-install':
    command     => "/usr/bin/drush -r /var/www/udb-drupal site-install -y culudb_kickstart --account-pass=${drupal_admin_account_pass} --db-url=${drupal_db_url} --uri=${drupal_uri}",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    onlyif      => '/usr/bin/test -z `/usr/bin/drush -r /var/www/udb-drupal core-status --format=list install-profile`',
    refreshonly => true,
    subscribe   => 'Package[udb3-drupal]',
    require     => 'File[udb3-drupal-settings]',
    noop        => $noop_deploy
  }

  exec { 'culturefeed-search-import-cities':
    command     => '/usr/bin/drush -r /var/www/udb-drupal culturefeed-search-import-cities',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => 'Exec[udb3-site-install]',
    require     => [ 'Package[udb3-drupal]', 'File[udb3-drupal-settings]'],
    refreshonly => true,
    notify      => 'Class[Supervisord::Service]',
    noop        => $noop_deploy
  }

  file { '/var/www/udb-drupal/sites/default/files':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Exec[udb3-site-install]',
    noop    => $noop_deploy
  }

  file { '/var/www/udb-drupal/sites/default/settings.php':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Exec[udb3-site-install]',
    noop    => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts udb3 drupal':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-alternative]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::udb3::drupal']
}
