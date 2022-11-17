class deployment::newsletter (
  $config_source,
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  realize Apt::Source['uitdatabank-newsletter-api']

  package { 'uitdatabank-newsletter-api':
    ensure  => 'latest',
    notify  => [ Class[apache::service], Profiles::Deployment::Versions[$title]],
    require => Apt::Source['uitdatabank-newsletter-api'],
    noop    => $noop_deploy
  }

  file { 'uitdatabank-newsletter-api-config':
    ensure  => 'file',
    path    => '/var/www/newsletter-api/config.yml',
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[uitdatabank-newsletter-api]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::newsletter']
}
