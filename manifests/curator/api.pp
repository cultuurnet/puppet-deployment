class deployment::curator::api (
  $config_source,
  $update_facts = false,
  $puppetdb_url = ''
) {

  realize Apt::Source['publiq-curator']

  package { 'curator-api':
    ensure  => 'latest',
    notify  => Class['apache::service'],
    require => Apt::Source['publiq-curator']
  }

  file { 'curator-api-config':
    ensure  => 'file',
    path    => '/var/www/curator-api/.env',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['curator-api'],
    notify  => Class['apache::service']
  }

  exec { 'curator-api_db_migrate':
    command     => 'php bin/console doctrine:schema:create',
    cwd         => '/var/www/curator-api',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin', '/var/www/curator-api'],
    subscribe   => Package['curator-api'],
    refreshonly => true
  }

  deployment::versions { $title:
    project      => 'curator',
    packages     => 'curator-api',
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::curator::api']
}
