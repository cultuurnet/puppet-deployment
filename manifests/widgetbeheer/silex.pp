class deployment::widgetbeheer::silex (
  $config_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  contain deployment

  package { 'widgetbeheer-silex':
    ensure => 'latest',
    notify => Class['apache::service'],
    noop   => $noop_deploy
  }

  file { 'widgetbeheer-silex-config':
    ensure  => 'file',
    path    => '/var/www/widgetbeheer-api/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['widgetbeheer-silex'],
    notify  => Class['apache::service'],
    noop    => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'widgetbeheer',
    packages     => 'widgetbeheer-silex',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::widgetbeheer::silex']
}
