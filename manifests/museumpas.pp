class deployment::museumpas (
  $config_source,
  $maintenance_source,
  $db_name,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  $basedir = '/var/www/museumpas'

  package { 'museumpas-website':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  package { 'museumpas-database':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'museumpas-files':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  file { 'museumpas-website-config':
    ensure  => 'file',
    path    => "${basedir}/.env",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[museumpas-website]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'museumpas-maintenance-pages':
    ensure  => 'directory',
    path    => "${basedir}/public/maintenance",
    recurse => true,
    source  => $maintenance_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[museumpas-website]',
    noop    => $noop_deploy
  }

  exec { 'import museumpas database dump':
    command   => "mysql --defaults-extra-file=/root/.my.cnf ${db_name} < /data/museumpas/db.sql",
    path      => [ '/usr/local/bin', '/usr/bin', '/bin'],
    logoutput => true,
    subscribe => Package['museumpas-database'],
    onlyif    => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${db_name}\";')",
    require   => File['museumpas-website-config'],
    noop      => $noop_deploy
  }

  exec { 'put museumpas in maintenance mode':
    command     => 'php artisan down',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => File['museumpas-website-config'],
    noop        => $noop_deploy
  }

  exec { 'run museumpas database migrations':
    command     => 'php artisan migrate --force',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => Package['museumpas-website'],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['import museumpas database dump'], Exec['put museumpas in maintenance mode'] ],
    noop        => $noop_deploy
  }

  exec { 'composer script post-autoload-dump':
    command     => 'vendor/bin/composer run-script post-autoload-dump',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', $basedir],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => Package['museumpas-website'],
    refreshonly => true,
    require     => File['museumpas-website-config'],
    noop        => $noop_deploy
  }

  exec { 'clear museumpas cache':
    command     => 'php artisan cache:clear',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['composer script post-autoload-dump'] ],
    noop        => $noop_deploy
  }

  exec { 'clear museumpas model cache':
    command     => 'php artisan modelCache:clear',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['composer script post-autoload-dump'], Exec['clear museumpas cache'] ],
    noop        => $noop_deploy
  }

  exec { 'clear museumpas views cache':
    command     => 'php artisan view:clear',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['composer script post-autoload-dump'], Exec['clear museumpas model cache'] ],
    noop        => $noop_deploy
  }

  exec { 'create storage link':
    command     => 'php artisan storage:link',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    logoutput   => true,
    unless      => "test -L ${basedir}/public/storage",
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['composer script post-autoload-dump'] ],
    noop        => $noop_deploy
  }

  exec { 'put museumpas in production mode':
    command     => 'php artisan up',
    cwd         => $basedir,
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    user        => 'www-data',
    environment => [ 'HOME=/'],
    logoutput   => true,
    subscribe   => [ Package['museumpas-website'], Package['museumpas-files'] ],
    refreshonly => true,
    require     => [ File['museumpas-website-config'], Exec['create storage link'], Exec['clear museumpas views cache'] ],
    noop        => $noop_deploy
  }

  if $update_facts {
    exec { 'update_facts museumpas':
      command     => "/usr/local/bin/update_facts ${puppetdb_url}",
      subscribe   => 'Package[museumpas-website]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::museumpas']
}
