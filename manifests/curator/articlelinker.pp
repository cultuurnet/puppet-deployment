class deployment::curator::articlelinker (
  $config_source,
  $publishers_source,
  $service_manage     = true,
  $service_ensure     = 'running',
  $service_enable     = true,
  $update_facts       = false,
  $puppetdb_url       = ''

) {

  realize Apt::Source['publiq-curator']

  package { 'curator-articlelinker':
    ensure  => 'latest',
    require => Apt::Source['publiq-curator']
  }

  file { '/var/www/curator-articlelinker/config.json':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $config_source,
    require => Package['curator-articlelinker']
  }

  file { '/var/www/curator-articlelinker/publishers.json':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    source  => $publishers_source,
    require => Package['curator-articlelinker']
  }

  if $service_manage {
    service { 'curator-articlelinker':
      ensure    => $service_ensure,
      enable    => $service_enable,
      require   => Package['curator-articlelinker'],
      hasstatus => true
    }

    File['/var/www/curator-articlelinker/config.json'] ~> Service['curator-articlelinker']
    File['/var/www/curator-articlelinker/publishers.json'] ~> Service['curator-articlelinker']
  }

   deployment::versions { $title:
    project      => 'curator',
    packages     => 'curator-articlelinker',
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
