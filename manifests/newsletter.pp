class deployment::newsletter (
  $config_source,
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'newsletter-silex':
    ensure => 'latest',
    notify => 'Class[Apache::Service]',
    noop   => $noop_deploy
  }

  file { 'newsletter-config':
    ensure  => 'file',
    path    => '/var/www/newsletter-silex/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[newsletter-silex]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'newsletter',
    packages     => 'newsletter-silex',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::newsletter']
}