class deployment::udb3::cdbxml (
  $config_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'udb3-cdbxml':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'udb3-cdbxml-config':
    ensure  => 'file',
    path    => '/var/www/udb-cdbxml/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[udb3-cdbxml]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  exec { 'udb3-db-install':
    command   => 'bin/app.php install',
    cwd       => '/var/www/udb-cdbxml',
    path      => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/udb-cdbxml'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\" and table_name not like \"doctrine_migration_versions\";')",
    subscribe => [ 'Package[udb3-cdbxml]', 'File[udb3-cdbxml-config]'],
    noop      => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts cdbxml':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[udb3-cdbxml]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['Php'] -> Class['Deployment::Udb3::Cdbxml']
}
